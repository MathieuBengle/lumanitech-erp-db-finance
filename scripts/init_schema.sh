#!/bin/bash

# ============================================================================
# Script: init_schema.sh
# Description: Initialize the database schema from scratch
# Usage: ./scripts/init_schema.sh [options]
# ============================================================================

set -e  # Exit on error

# Configuration
DB_NAME="lumanitech_erp_finance"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SCHEMA_DIR="$PROJECT_ROOT/schema"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Function to check if MySQL is available
check_mysql() {
    if ! command -v mysql &> /dev/null; then
        print_error "MySQL client is not installed or not in PATH"
        exit 1
    fi
    print_info "MySQL client found"
}

# Function to execute SQL file
execute_sql() {
    local file=$1
    local db=$2
    
    print_info "Executing: $(basename "$file")"
    
    if [ -z "$db" ]; then
        mysql -u "${MYSQL_USER:-root}" -p"${MYSQL_PASSWORD}" < "$file"
    else
        mysql -u "${MYSQL_USER:-root}" -p"${MYSQL_PASSWORD}" "$db" < "$file"
    fi
    
    if [ $? -eq 0 ]; then
        print_info "✓ Successfully executed $(basename "$file")"
        return 0
    else
        print_error "✗ Failed to execute $(basename "$file")"
        return 1
    fi
}

# Main execution
main() {
    print_info "Starting database schema initialization..."
    print_info "Database: $DB_NAME"
    
    # Check prerequisites
    check_mysql
    
    # Check if schema directory exists
    if [ ! -d "$SCHEMA_DIR" ]; then
        print_error "Schema directory not found: $SCHEMA_DIR"
        exit 1
    fi
    
    # Prompt for MySQL password if not set
    if [ -z "$MYSQL_PASSWORD" ]; then
        print_warning "MYSQL_PASSWORD not set in environment"
        read -sp "Enter MySQL password: " MYSQL_PASSWORD
        echo
        export MYSQL_PASSWORD
    fi
    
    # Execute schema files in order
    print_info "Executing schema files..."
    
    # First create the database
    execute_sql "$SCHEMA_DIR/01_create_database.sql" || exit 1
    
    # Then create tables
    for sql_file in "$SCHEMA_DIR"/*.sql; do
        # Skip the database creation file (already executed)
        if [[ "$sql_file" == *"01_create_database.sql"* ]]; then
            continue
        fi
        
        execute_sql "$sql_file" "$DB_NAME" || exit 1
    done
    
    print_info "Schema initialization completed successfully!"
    print_info "Next steps:"
    echo "  1. Apply migrations: ./scripts/migrate.sh"
    echo "  2. Load seed data: ./scripts/seed.sh"
}

# Run main function
main "$@"
