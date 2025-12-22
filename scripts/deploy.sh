#!/bin/bash

# ============================================================================
# Script: deploy.sh
# Description: Deploy database schema, migrations, and optionally seed data
# Usage: ./scripts/deploy.sh [--with-seeds] [--login-path=name]
# ============================================================================

set -e  # Exit on error

# Configuration
DB_NAME="lumanitech_erp_finance"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SCHEMA_DIR="$PROJECT_ROOT/schema"
MIGRATION_DIR="$PROJECT_ROOT/migrations"
SEED_DIR="$PROJECT_ROOT/seeds"

# Default login path for mysql_config_editor
LOGIN_PATH="local"
WITH_SEEDS=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_migration() {
    echo -e "${BLUE}[MIGRATION]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy database schema, migrations, and optionally seed data.

OPTIONS:
    --with-seeds            Load seed data after migrations (dev/test only)
    --login-path=NAME       MySQL login path name (default: local)
    -h, --help              Show this help message

EXAMPLES:
    # Deploy schema and migrations using default login path
    $0

    # Deploy with seed data
    $0 --with-seeds

    # Use specific login path
    $0 --login-path=production

MYSQL LOGIN PATH:
    This script uses mysql_config_editor to store credentials securely.
    To set up a login path:

    mysql_config_editor set --login-path=local \\
        --host=localhost \\
        --user=root \\
        --password

    To list configured login paths:
    mysql_config_editor print --all

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
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

# Function to check if MySQL client is available
check_mysql() {
    if ! command -v mysql &> /dev/null; then
        print_error "MySQL client is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v mysql_config_editor &> /dev/null; then
        print_error "mysql_config_editor is not installed or not in PATH"
        exit 1
    fi
}

# Function to verify login path exists
verify_login_path() {
    if ! mysql_config_editor print --login-path="$LOGIN_PATH" &> /dev/null; then
        print_error "Login path '$LOGIN_PATH' not found"
        print_info "To create it, run:"
        echo "  mysql_config_editor set --login-path=$LOGIN_PATH --host=localhost --user=root --password"
        exit 1
    fi
    print_info "Using login path: $LOGIN_PATH"
}

# Function to execute SQL file
execute_sql() {
    local file=$1
    local db=$2
    
    print_info "Executing: $(basename "$file")"
    
    if [ -z "$db" ]; then
        mysql --login-path="$LOGIN_PATH" < "$file"
    else
        mysql --login-path="$LOGIN_PATH" "$db" < "$file"
    fi
    
    if [ $? -eq 0 ]; then
        print_info "✓ Successfully executed $(basename "$file")"
        return 0
    else
        print_error "✗ Failed to execute $(basename "$file")"
        return 1
    fi
}

# Function to extract version from migration filename
get_version() {
    local filename=$(basename "$1")
    echo "$filename" | sed 's/V\([0-9]*\)__.*/\1/'
}

# Function to extract description from migration filename
get_description() {
    local filename=$(basename "$1")
    echo "$filename" | sed 's/V[0-9]*__\(.*\)\.sql/\1/' | tr '_' ' '
}

# Function to check if migration is applied
is_migration_applied() {
    local version=$1
    local result=$(mysql --login-path="$LOGIN_PATH" -D "$DB_NAME" -sN -e \
        "SELECT COUNT(*) FROM schema_migrations WHERE version = 'V$version' AND success = TRUE" 2>/dev/null || echo "0")
    
    if [ "$result" -gt 0 ]; then
        return 0  # Migration is applied
    else
        return 1  # Migration is not applied
    fi
}

# Function to record migration
record_migration() {
    local version=$1
    local description=$2
    local script_name=$3
    local execution_time=$4
    local installed_by="${USER:-system}"
    
    mysql --login-path="$LOGIN_PATH" -D "$DB_NAME" -e \
        "INSERT INTO schema_migrations (version, description, script_name, installed_by, execution_time, success) 
         VALUES ('V$version', '$description', '$script_name', '$installed_by', $execution_time, TRUE);"
}

# Function to apply migration
apply_migration() {
    local file=$1
    local version=$(get_version "$file")
    local description=$(get_description "$file")
    local script_name=$(basename "$file")
    
    print_migration "Applying V$version: $description"
    
    local start_time=$(date +%s%3N)
    
    mysql --login-path="$LOGIN_PATH" -D "$DB_NAME" < "$file"
    
    if [ $? -ne 0 ]; then
        print_error "Migration V$version failed"
        return 1
    fi
    
    local end_time=$(date +%s%3N)
    local execution_time=$((end_time - start_time))
    
    record_migration "$version" "$description" "$script_name" "$execution_time"
    
    print_info "✓ Migration V$version applied successfully (${execution_time}ms)"
}

# Function to check if database exists
database_exists() {
    mysql --login-path="$LOGIN_PATH" -e "USE $DB_NAME" 2>/dev/null
    return $?
}

# Function to initialize schema
init_schema() {
    print_info "=== STEP 1: Initialize Schema ==="
    
    if [ ! -d "$SCHEMA_DIR" ]; then
        print_error "Schema directory not found: $SCHEMA_DIR"
        exit 1
    fi
    
    # Create database
    print_info "Creating database..."
    execute_sql "$SCHEMA_DIR/01_create_database.sql" || exit 1
    
    # Create tables
    print_info "Creating tables..."
    for sql_file in "$SCHEMA_DIR"/*.sql; do
        # Skip the database creation file (already executed)
        if [[ "$sql_file" == *"01_create_database.sql"* ]]; then
            continue
        fi
        
        execute_sql "$sql_file" "$DB_NAME" || exit 1
    done
    
    print_info "Schema initialization completed"
    echo
}

# Function to apply migrations
apply_migrations() {
    print_info "=== STEP 2: Apply Migrations ==="
    
    if [ ! -d "$MIGRATION_DIR" ]; then
        print_error "Migration directory not found: $MIGRATION_DIR"
        exit 1
    fi
    
    # Get list of migration files
    migration_files=($(ls -1 "$MIGRATION_DIR"/V*.sql 2>/dev/null | sort -V))
    
    if [ ${#migration_files[@]} -eq 0 ]; then
        print_warning "No migration files found in $MIGRATION_DIR"
        return 0
    fi
    
    print_info "Found ${#migration_files[@]} migration file(s)"
    
    # Process each migration
    local applied_count=0
    local skipped_count=0
    
    for migration_file in "${migration_files[@]}"; do
        version=$(get_version "$migration_file")
        
        if is_migration_applied "$version"; then
            print_info "Skipping V$version (already applied)"
            ((skipped_count++))
        else
            apply_migration "$migration_file" || exit 1
            ((applied_count++))
        fi
    done
    
    print_info "Migration process completed"
    print_info "Applied: $applied_count, Skipped: $skipped_count"
    
    # Show current migration status
    if [ $applied_count -gt 0 ] || [ $skipped_count -gt 0 ]; then
        print_info "Current migration status:"
        mysql --login-path="$LOGIN_PATH" -D "$DB_NAME" -t -e \
            "SELECT version, description, installed_on, execution_time FROM schema_migrations ORDER BY id;"
    fi
    
    echo
}

# Function to load seed data
load_seeds() {
    print_info "=== STEP 3: Load Seed Data ==="
    
    if [ ! -d "$SEED_DIR" ]; then
        print_error "Seed directory not found: $SEED_DIR"
        exit 1
    fi
    
    # Warning about seed data
    print_warning "WARNING: Seed data is for development/testing only!"
    print_warning "Do NOT run this on production databases!"
    echo
    
    # Execute seed files in order
    print_info "Loading seed files..."
    
    for seed_file in "$SEED_DIR"/*.sql; do
        if [ -f "$seed_file" ]; then
            print_info "Loading: $(basename "$seed_file")"
            mysql --login-path="$LOGIN_PATH" "$DB_NAME" < "$seed_file" || exit 1
            print_info "✓ Successfully loaded $(basename "$seed_file")"
        fi
    done
    
    print_info "Seed data loaded successfully!"
    echo
}

# Main execution
main() {
    print_info "========================================"
    print_info "Database Deployment Script"
    print_info "Database: $DB_NAME"
    print_info "Login Path: $LOGIN_PATH"
    print_info "With Seeds: $WITH_SEEDS"
    print_info "========================================"
    echo
    
    # Check prerequisites
    check_mysql
    verify_login_path
    
    # Check if database already exists
    if database_exists; then
        print_warning "Database '$DB_NAME' already exists"
        print_info "Skipping schema initialization, will only apply migrations"
        echo
        apply_migrations
    else
        print_info "Database '$DB_NAME' does not exist"
        print_info "Will create schema and apply migrations"
        echo
        init_schema
        apply_migrations
    fi
    
    # Load seeds if requested
    if [ "$WITH_SEEDS" = true ]; then
        load_seeds
    fi
    
    print_info "========================================"
    print_info "Deployment completed successfully!"
    print_info "========================================"
}

# Run main function
main "$@"
