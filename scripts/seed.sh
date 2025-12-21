#!/bin/bash

# ============================================================================
# Script: seed.sh
# Description: Load seed data into the database
# Usage: ./scripts/seed.sh [options]
# ============================================================================

set -e  # Exit on error

# Configuration
DB_NAME="lumanitech_erp_finance"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SEED_DIR="$PROJECT_ROOT/seeds"

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

# Function to execute SQL file
execute_seed() {
    local file=$1
    
    print_info "Loading: $(basename "$file")"
    
    mysql -u "${MYSQL_USER:-root}" -p"${MYSQL_PASSWORD}" "$DB_NAME" < "$file"
    
    if [ $? -eq 0 ]; then
        print_info "✓ Successfully loaded $(basename "$file")"
        return 0
    else
        print_error "✗ Failed to load $(basename "$file")"
        return 1
    fi
}

# Main execution
main() {
    print_info "Starting seed data loading process..."
    print_info "Database: $DB_NAME"
    
    # Warning about seed data
    print_warning "WARNING: Seed data is for development/testing only!"
    print_warning "Do NOT run this on production databases!"
    echo
    read -p "Are you sure you want to continue? (yes/no): " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        print_info "Seed loading cancelled"
        exit 0
    fi
    
    # Check if MySQL is available
    if ! command -v mysql &> /dev/null; then
        print_error "MySQL client is not installed or not in PATH"
        exit 1
    fi
    
    # Check if seed directory exists
    if [ ! -d "$SEED_DIR" ]; then
        print_error "Seed directory not found: $SEED_DIR"
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
    if ! mysql -u "${MYSQL_USER:-root}" -p"${MYSQL_PASSWORD}" -e "USE $DB_NAME" 2>/dev/null; then
        print_error "Database $DB_NAME does not exist. Please run init_schema.sh and migrate.sh first."
        exit 1
    fi
    
    # Execute seed files in order
    print_info "Loading seed files..."
    
    for seed_file in "$SEED_DIR"/*.sql; do
        if [ -f "$seed_file" ]; then
            execute_seed "$seed_file" || exit 1
        fi
    done
    
    print_info "Seed data loaded successfully!"
}

# Run main function
main "$@"
