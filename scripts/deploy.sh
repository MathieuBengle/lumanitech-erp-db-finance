#!/bin/bash
# Deploys the finance database while reusing mysql_config_editor login-path credentials.

set -euo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SCHEMA_DIR="$PROJECT_ROOT/schema"
MIGRATION_DIR="$PROJECT_ROOT/migrations"
SEED_DIR="$PROJECT_ROOT/seeds/dev"

# Defaults
DB_NAME="lumanitech_erp_finance"
DB_HOST="localhost"
DB_USER="admin"
LOGIN_PATH="local"
WITH_SEEDS=false
MYSQL_PASSWORD=""
MYSQL_CMD=()

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    cat <<'EOF'
Usage: deploy.sh [OPTIONS]

Deploy the finance database schema, migrations, and optional seed data.

Options:
  -d, --database NAME     Database name (default: lumanitech_erp_finance)
  --host HOST             MySQL host (default: localhost)
  --user USER             Database user (default: admin)
  --with-seeds           Load seed data from seeds/dev
  --login-path=NAME       mysql_config_editor login path (default: local)
  -h, --help              Show this help message

Examples:
  ./scripts/deploy.sh
  ./scripts/deploy.sh --with-seeds
  ./scripts/deploy.sh --login-path=local --database=lumanitech_erp_finance
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
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

ensure_mysql_client() {
    if ! command -v mysql &> /dev/null; then
        error "MySQL client not found"
        exit 1
    fi
}

verify_login_path() {
    if ! command -v mysql_config_editor &> /dev/null; then
        error "mysql_config_editor is required when using login paths"
        exit 1
    fi
    if ! mysql_config_editor print --login-path="$LOGIN_PATH" &> /dev/null; then
        error "Login path '$LOGIN_PATH' not found"
        info "Create it with:"
        echo "  mysql_config_editor set --login-path=$LOGIN_PATH --host=$DB_HOST --user=$DB_USER --password"
        exit 1
    fi
    info "Using login path: $LOGIN_PATH"
}

prompt_password() {
    read -s -p "Enter MySQL password for '$DB_USER'@'$DB_HOST': " MYSQL_PASSWORD
    echo
}

build_mysql_cmd() {
    if [ -n "$LOGIN_PATH" ]; then
        verify_login_path
        MYSQL_CMD=(mysql --login-path="$LOGIN_PATH" -h "$DB_HOST")
    else
        prompt_password
        MYSQL_CMD=(mysql -h "$DB_HOST" -u "$DB_USER" -p"$MYSQL_PASSWORD")
    fi
}

mysql_exec() {
    "${MYSQL_CMD[@]}" "$@"
}

run_sql_dir() {
    local label=$1
    local path=$2
    local db=${3:-}
    if [ ! -d "$path" ]; then
        warn "Skipping $label (directory not found: $path)"
        return
    fi
    local files=("$path"/*.sql)
    if [ ${#files[@]} -eq 0 ]; then
        warn "No SQL files found in $path"
        return
    fi
    IFS=$'\n' files_sorted=($(printf '%s\n' "${files[@]}" | sort))
    unset IFS
    for file in "${files_sorted[@]}"; do
        info "Executing $label: $(basename "$file")"
        if [ -n "$db" ]; then
            mysql_exec -D "$db" < "$file"
        else
            mysql_exec < "$file"
        fi
    done
}

ensure_database() {
    info "Ensuring database '$DB_NAME' exists"
    mysql_exec -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
}

apply_migrations() {
    info "Applying migrations"
    if [ ! -d "$MIGRATION_DIR" ]; then
        warn "No migrations directory ($MIGRATION_DIR)"
        return
    fi
    mapfile -t migrations < <(printf '%s\n' "$MIGRATION_DIR"/*.sql | sort)
    if [ ${#migrations[@]} -eq 0 ]; then
        warn "No migration files found"
        return
    fi
    for migration in "${migrations[@]}"; do
        # Skip TEMPLATE.sql
        if [[ "$(basename "$migration")" == "TEMPLATE.sql" ]]; then
            continue
        fi
        info "Running migration $(basename "$migration")"
        mysql_exec -D "$DB_NAME" < "$migration"
    done
}

load_seed_data() {
    if [ "$WITH_SEEDS" != true ]; then
        return
    fi
    info "Loading seed data"
    if [ ! -d "$SEED_DIR" ]; then
        warn "Seed directory not found ($SEED_DIR)"
        return
    fi
    for seed in "$(ls "$SEED_DIR"/*.sql 2>/dev/null | sort)"; do
        if [ -f "$seed" ]; then
            info "Executing seed $(basename "$seed")"
            mysql_exec -D "$DB_NAME" < "$seed"
        fi
    done
}

main() {
    info "Starting Finance DB deployment"
    info "Database: $DB_NAME"
    info "Host: $DB_HOST"
    info "User: $DB_USER"
    info "Login path: ${LOGIN_PATH:-(interactive)}"
    info "With seeds: $WITH_SEEDS"
    ensure_mysql_client
    build_mysql_cmd
    info "Testing connection"
    mysql_exec -e "SELECT 1" &> /dev/null
    info "Connection ok"
    ensure_database
    run_sql_dir "database" "$SCHEMA_DIR" ""
    run_sql_dir "tables" "$SCHEMA_DIR/tables" "$DB_NAME"
    run_sql_dir "views" "$SCHEMA_DIR/views" "$DB_NAME"
    run_sql_dir "procedures" "$SCHEMA_DIR/procedures" "$DB_NAME"
    run_sql_dir "functions" "$SCHEMA_DIR/functions" "$DB_NAME"
    run_sql_dir "triggers" "$SCHEMA_DIR/triggers" "$DB_NAME"
    run_sql_dir "indexes" "$SCHEMA_DIR/indexes" "$DB_NAME"
    apply_migrations
    load_seed_data
    info "Finance database deployment complete"
}

main "$@"
