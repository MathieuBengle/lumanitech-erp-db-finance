#!/bin/bash

# ============================================================================
# Script: migrate.sh
# Description: Apply database migrations with tracking
# Usage: ./scripts/migrate.sh [options]
# ============================================================================

set -e  # Exit on error

# Configuration
DB_NAME="lumanitech_erp_finance"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MIGRATION_DIR="$PROJECT_ROOT/migrations"

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

# Function to extract version from filename
get_version() {
    local filename=$(basename "$1")
    echo "$filename" | sed 's/V\([0-9]*\)__.*/\1/'
}

# Function to extract description from filename
get_description() {
    local filename=$(basename "$1")
    echo "$filename" | sed 's/V[0-9]*__\(.*\)\.sql/\1/' | tr '_' ' '
}

# Function to check if migration is applied
is_migration_applied() {
    local version=$1
    export MYSQL_PWD="${MYSQL_PASSWORD}"
    local result=$(mysql -u "${MYSQL_USER:-root}" -D "$DB_NAME" -sN -e \
        "SELECT COUNT(*) FROM schema_migrations WHERE version = 'V$version' AND success = TRUE" 2>/dev/null || echo "0")
    unset MYSQL_PWD
    
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
    
    export MYSQL_PWD="${MYSQL_PASSWORD}"
    mysql -u "${MYSQL_USER:-root}" -D "$DB_NAME" -e \
        "INSERT INTO schema_migrations (version, description, script_name, installed_by, execution_time, success) 
         VALUES ('V$version', '$description', '$script_name', '$installed_by', $execution_time, TRUE);"
    unset MYSQL_PWD
}

# Function to apply migration
apply_migration() {
    local file=$1
    local version=$(get_version "$file")
    local description=$(get_description "$file")
    local script_name=$(basename "$file")
    
    print_migration "Applying V$version: $description"
    
    local start_time=$(date +%s%3N)
    
    export MYSQL_PWD="${MYSQL_PASSWORD}"
    mysql -u "${MYSQL_USER:-root}" -D "$DB_NAME" < "$file"
    local exit_code=$?
    unset MYSQL_PWD
    
    if [ $exit_code -ne 0 ]; then
        return $exit_code
    fi
    
    local end_time=$(date +%s%3N)
    local execution_time=$((end_time - start_time))
    
    record_migration "$version" "$description" "$script_name" "$execution_time"
    
    print_info "✓ Migration V$version applied successfully (${execution_time}ms)"
}

# Main execution
main() {
    print_info "Starting database migration process..."
    print_info "Database: $DB_NAME"
    
    # Check if MySQL is available
    if ! command -v mysql &> /dev/null; then
        print_error "MySQL client is not installed or not in PATH"
        exit 1
    fi
    
    # Check if migration directory exists
    if [ ! -d "$MIGRATION_DIR" ]; then
        print_error "Migration directory not found: $MIGRATION_DIR"
        exit 1
    fi
    
    # Prompt for MySQL password if not set
    if [ -z "$MYSQL_PASSWORD" ]; then
        print_warning "MYSQL_PASSWORD not set in environment"
        read -sp "Enter MySQL password: " MYSQL_PASSWORD
        echo
        export MYSQL_PASSWORD
    fi
    
    # Check if database exists
    export MYSQL_PWD="${MYSQL_PASSWORD}"
    if ! mysql -u "${MYSQL_USER:-root}" -e "USE $DB_NAME" 2>/dev/null; then
        unset MYSQL_PWD
        print_error "Database $DB_NAME does not exist. Please run init_schema.sh first."
        exit 1
    fi
    unset MYSQL_PWD
    
    # Get list of migration files
    migration_files=($(ls -1 "$MIGRATION_DIR"/V*.sql 2>/dev/null | sort -V))
    
    if [ ${#migration_files[@]} -eq 0 ]; then
        print_warning "No migration files found in $MIGRATION_DIR"
        exit 0
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
            apply_migration "$migration_file"
            ((applied_count++))
        fi
    done
    
    print_info "Migration process completed"
    print_info "Applied: $applied_count, Skipped: $skipped_count"
    
    # Show current migration status
    print_info "Current migration status:"
    export MYSQL_PWD="${MYSQL_PASSWORD}"
    mysql -u "${MYSQL_USER:-root}" -D "$DB_NAME" -t -e \
        "SELECT version, description, installed_on, execution_time FROM schema_migrations ORDER BY id;"
    unset MYSQL_PWD
}

# Run main function
main "$@"
