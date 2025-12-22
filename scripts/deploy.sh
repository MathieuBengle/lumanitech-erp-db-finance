#!/bin/bash
# Database deployment script that keeps the mysql_config_editor + interactive password flow in sync
# with the other Lumanitech ERP database repositories (erp-db-core, erp-db-projects).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SCHEMA_DIR="$PROJECT_ROOT/schema"
MIGRATION_DIR="$PROJECT_ROOT/migrations"
SEED_DIR="$PROJECT_ROOT/seeds"

# Default configuration
DB_NAME="lumanitech_erp_finance"
DB_HOST="localhost"
DB_USER="root"
LOGIN_PATH=""
WITH_SEEDS=false
MYSQL_PASSWORD=""
MYSQL_CMD=()

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_migration() {
    echo -e "${BLUE}[MIGRATION]${NC} $1"
}

show_usage() {
    cat <<'EOF'
Usage: deploy.sh [OPTIONS]

Deploy the finance database schema, migrations, and optionally seed data for development or CI.

Options:
  -d, --database NAME     Database name (default: lumanitech_erp_finance)
  --host HOST             MySQL host (default: localhost)
  --user USER             MySQL user (default: root)
  --with-seeds           Load seed data after migrations (dev/test only)
  --login-path=NAME       mysql_config_editor login path to use (default: auto-detect)
  -h, --help              Show this help message

Examples:
  ./scripts/deploy.sh
  ./scripts/deploy.sh --with-seeds
  ./scripts/deploy.sh --database=lumanitech_projects --login-path=production
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--database)
            DB_NAME="$2"
            shift 2
            ;;
        -d=*|--database=*)
            DB_NAME="${1#*=}"
            shift
            ;;
        --host=*)
            DB_HOST="${1#*=}"
            shift
            ;;
        --user=*)
            DB_USER="${1#*=}"
            shift
            ;;
        --with-seeds)
            WITH_SEEDS=true
            shift
            ;;
        --login-path=*)
            LOGIN_PATH="${1#*=}"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

check_mysql_clients() {
    if ! command -v mysql &> /dev/null; then
        print_error "MySQL client is not installed or not in PATH"
        exit 1
    fi
}

detect_login_path() {
    if [ -n "$LOGIN_PATH" ]; then
        return
    fi
    if [ -n "${MYSQL_LOGIN_PATH:-}" ]; then
        LOGIN_PATH="${MYSQL_LOGIN_PATH:-}"
        return
    fi
    if command -v mysql_config_editor &> /dev/null; then
        local candidate
        candidate=$(mysql_config_editor print --all 2>/dev/null | awk '/^\[.*\]/{gsub(/\[|\]/, "", $0); print; exit}') || true
        if [ -n "$candidate" ]; then
            LOGIN_PATH="$candidate"
        fi
    fi
}

verify_login_path() {
    if ! command -v mysql_config_editor &> /dev/null; then
        print_error "mysql_config_editor is required when a login path is used"
        exit 1
    fi
    if ! mysql_config_editor print --login-path="$LOGIN_PATH" &> /dev/null; then
        print_error "Login path '$LOGIN_PATH' not found"
        print_info "Create it with:"
        echo "  mysql_config_editor set --login-path=$LOGIN_PATH --host=$DB_HOST --user=$DB_USER --password"
        exit 1
    fi
    print_info "Using login path: $LOGIN_PATH"
}

prompt_for_password() {
    read -s -p "Enter MySQL password for '$DB_USER'@'$DB_HOST': " MYSQL_PASSWORD
    echo
}

build_mysql_command() {
    if [ -n "$LOGIN_PATH" ]; then
        MYSQL_CMD=(mysql --login-path="$LOGIN_PATH" -h "$DB_HOST")
    else
        prompt_for_password
        MYSQL_CMD=(mysql -h "$DB_HOST" -u "$DB_USER" -p"$MYSQL_PASSWORD")
    fi
}

mysql_exec() {
    "${MYSQL_CMD[@]}" "$@"
}

execute_sql() {
    local file=$1
    local db=$2
    print_info "Executing: $(basename "$file")"
    if [ -n "$db" ]; then
        if mysql_exec -D "$db" < "$file"; then
            print_info "✓ $(basename "$file")"
        else
            print_error "Failed to execute $(basename "$file")"
            exit 1
        fi
    else
        if mysql_exec < "$file"; then
            print_info "✓ $(basename "$file")"
        else
            print_error "Failed to execute $(basename "$file")"
            exit 1
        fi
    fi
}

get_version() {
    local filename
    filename=$(basename "$1")
    echo "$filename" | sed 's/V\([0-9]*\)__.*\.sql/\1/'
}

get_description() {
    local filename
    filename=$(basename "$1")
    echo "$filename" | sed 's/V[0-9]*__\(.*\)\.sql/\1/' | tr '_' ' '
}

is_migration_applied() {
    local version=$1
    local result
    result=$(mysql_exec -D "$DB_NAME" -sN -e "SELECT COUNT(*) FROM schema_migrations WHERE version = 'V$version' AND success = TRUE" 2>/dev/null || echo "0")
    [ "$result" -gt 0 ] && return 0 || return 1
}

record_migration() {
    local version=$1 description=$2 script_name=$3 execution_time=$4
    local installed_by="${USER:-system}"
    mysql_exec -D "$DB_NAME" -e \
        "INSERT INTO schema_migrations (version, description, script_name, installed_by, execution_time, success) \
         VALUES ('V$version', '$description', '$script_name', '$installed_by', $execution_time, TRUE);"
}

apply_migration() {
    local file=$1
    local version
    version=$(get_version "$file")
    local description
    description=$(get_description "$file")
    local script_name
    script_name=$(basename "$file")
    print_migration "Applying V$version: $description"
    local start_time end_time execution_time
    start_time=$(date +%s%3N)
    if ! mysql_exec -D "$DB_NAME" < "$file"; then
        print_error "Migration V$version failed"
        exit 1
    fi
    end_time=$(date +%s%3N)
    execution_time=$((end_time - start_time))
    record_migration "$version" "$description" "$script_name" "$execution_time"
    print_info "✓ Migration V$version applied (${execution_time}ms)"
}

database_exists() {
    mysql_exec -D "$DB_NAME" -e "SELECT 1" &> /dev/null
}

init_schema() {
    print_info "=== STEP 1: Initialize Schema ==="
    if [ ! -d "$SCHEMA_DIR" ]; then
        print_error "Schema directory not found: $SCHEMA_DIR"
        exit 1
    fi
    print_info "Creating database"
    execute_sql "$SCHEMA_DIR/01_create_database.sql" ""
    print_info "Creating tables"
    for sql_file in "$SCHEMA_DIR"/*.sql; do
        if [[ "$(basename "$sql_file")" == "01_create_database.sql" ]]; then
            continue
        fi
        execute_sql "$sql_file" "$DB_NAME"
    done
    print_info "Schema initialization completed"
    echo
}

apply_migrations() {
    print_info "=== STEP 2: Apply Migrations ==="
    if [ ! -d "$MIGRATION_DIR" ]; then
        print_error "Migration directory not found: $MIGRATION_DIR"
        exit 1
    fi
    mapfile -t migration_files < <(ls -1 "$MIGRATION_DIR"/V*.sql 2>/dev/null | sort -V)
    if [ ${#migration_files[@]} -eq 0 ]; then
        print_warning "No migration files found"
        return
    fi
    print_info "Found ${#migration_files[@]} migration(s)"
    local applied=0 skipped=0
    for migration_file in "${migration_files[@]}"; do
        local version
        version=$(get_version "$migration_file")
        if is_migration_applied "$version"; then
            print_info "Skipping V$version (already applied)"
            ((skipped++))
            continue
        fi
        apply_migration "$migration_file"
        ((applied++))
    done
    print_info "Migration process completed (applied: $applied, skipped: $skipped)"
    if [ $((applied + skipped)) -gt 0 ]; then
        mysql_exec -D "$DB_NAME" -t -e "SELECT version, description, installed_on, execution_time FROM schema_migrations ORDER BY id;"
    fi
    echo
}

load_seeds() {
    print_info "=== STEP 3: Load Seed Data ==="
    if [ ! -d "$SEED_DIR" ]; then
        print_error "Seed directory not found: $SEED_DIR"
        exit 1
    fi
    print_warning "Seed data is for development/testing only. Do not run on production."
    for seed_file in "$SEED_DIR"/*.sql; do
        if [ -f "$seed_file" ]; then
            print_info "Loading $(basename "$seed_file")"
            mysql_exec -D "$DB_NAME" < "$seed_file"
            print_info "✓ $(basename "$seed_file") loaded"
        fi
    done
    print_info "Seed data loaded successfully"
    echo
}

main() {
    print_info "========================================"
    print_info "Database Deployment Script"
    print_info "Database: $DB_NAME"
    if [ -n "$LOGIN_PATH" ]; then
        print_info "Login Path: $LOGIN_PATH"
    else
        print_info "Login Path: (interactive password)"
    fi
    print_info "Host: $DB_HOST"
    print_info "User: $DB_USER"
    print_info "With Seeds: $WITH_SEEDS"
    print_info "========================================"
    echo
    check_mysql_clients
    detect_login_path
    if [ -n "$LOGIN_PATH" ]; then
        verify_login_path
    fi
    build_mysql_command
    print_info "Testing database connection..."
    if ! mysql_exec -e "SELECT 1" &> /dev/null; then
        print_error "Cannot connect to MySQL. Check credentials or login path."
        exit 1
    fi
    print_info "✓ Database connection successful"
    echo
    if database_exists; then
        print_warning "Database '$DB_NAME' already exists"
        print_info "Skipping schema initialization, applying migrations only"
        echo
        apply_migrations
    else
        print_info "Database '$DB_NAME' does not exist"
        print_info "Initializing schema and applying migrations"
        echo
        init_schema
        apply_migrations
    fi
    if [ "$WITH_SEEDS" = true ]; then
        load_seeds
    fi
    print_info "========================================"
    print_info "Deployment completed successfully"
    print_info "========================================"
}

main "$@"
