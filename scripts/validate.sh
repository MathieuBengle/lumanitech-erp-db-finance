#!/bin/bash

# ============================================================================
# Script: validate.sh
# Description: Validate SQL files for syntax errors (CI-ready)
# Usage: ./scripts/validate.sh
# Exit codes: 0 = success, 1 = validation errors found
# ============================================================================

# Note: We don't use 'set -e' here because we want to validate all files
# and report all errors, not exit on the first one

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
total_files=0
valid_files=0
invalid_files=0

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to validate SQL file
validate_sql_file() {
    local file=$1
    local relative_path=$(realpath --relative-to="$PROJECT_ROOT" "$file")
    
    ((total_files++))
    
    # Basic syntax checks
    local errors=()
    
    # Check 1: File is not empty
    if [ ! -s "$file" ]; then
        errors+=("File is empty")
    fi
    
    # Check 2: File contains SQL keywords
    if ! grep -qi -E "(CREATE|ALTER|INSERT|UPDATE|DELETE|SELECT|DROP|USE)" "$file"; then
        errors+=("No SQL keywords found")
    fi
    
    # Check 3: Balanced parentheses
    local open_parens=$(grep -o "(" "$file" | wc -l)
    local close_parens=$(grep -o ")" "$file" | wc -l)
    if [ "$open_parens" -ne "$close_parens" ]; then
        errors+=("Unbalanced parentheses (open: $open_parens, close: $close_parens)")
    fi
    
    # Check 4: No tabs (prefer spaces)
    if grep -q $'\t' "$file"; then
        print_warning "$relative_path: Contains tabs (spaces preferred)"
    fi
    
    # Check 5: File ends with newline
    if [ -n "$(tail -c 1 "$file")" ]; then
        print_warning "$relative_path: File does not end with newline"
    fi
    
    # Check 6: Migration files follow naming convention
    if [[ "$file" == *"/migrations/"* ]]; then
        local filename=$(basename "$file")
        if ! [[ "$filename" =~ ^V[0-9]+__[a-z_]+\.sql$ ]]; then
            errors+=("Migration file does not follow naming convention V###__description.sql")
        fi
    fi
    
    # Check 7: UTF-8 encoding (ASCII is acceptable as it's a subset of UTF-8)
    if ! file "$file" | grep -qE "(UTF-8|ASCII)"; then
        errors+=("File is not UTF-8/ASCII encoded")
    fi
    
    # Report results
    if [ ${#errors[@]} -eq 0 ]; then
        print_success "✓ $relative_path"
        ((valid_files++))
        return 0
    else
        print_error "✗ $relative_path"
        for error in "${errors[@]}"; do
            echo "    - $error"
        done
        ((invalid_files++))
        return 1
    fi
}

# Function to check MySQL syntax if available
check_mysql_syntax() {
    local file=$1
    
    if ! command -v mysql &> /dev/null; then
        return 0  # Skip if MySQL not available
    fi
    
    # Try to parse the SQL (dry-run)
    # Note: This requires MySQL to be running
    # For CI, we may skip this or use a docker container
    return 0
}

# Main execution
main() {
    print_info "Starting SQL validation..."
    print_info "Project root: $PROJECT_ROOT"
    echo
    
    # Validate schema files
    if [ -d "$PROJECT_ROOT/schema" ]; then
        print_info "Validating schema files..."
        for sql_file in "$PROJECT_ROOT/schema"/*.sql; do
            if [ -f "$sql_file" ]; then
                validate_sql_file "$sql_file"
            fi
        done
        echo
    fi
    
    # Validate migration files
    if [ -d "$PROJECT_ROOT/migrations" ]; then
        print_info "Validating migration files..."
        for sql_file in "$PROJECT_ROOT/migrations"/*.sql; do
            if [ -f "$sql_file" ]; then
                validate_sql_file "$sql_file"
            fi
        done
        echo
    fi
    
    # Validate seed files
    if [ -d "$PROJECT_ROOT/seeds" ]; then
        print_info "Validating seed files..."
        for sql_file in "$PROJECT_ROOT/seeds"/*.sql; do
            if [ -f "$sql_file" ]; then
                validate_sql_file "$sql_file"
            fi
        done
        echo
    fi
    
    # Print summary
    echo "========================================"
    print_info "Validation Summary"
    echo "========================================"
    echo "Total files:   $total_files"
    echo "Valid files:   $valid_files"
    echo "Invalid files: $invalid_files"
    echo "========================================"
    
    if [ $invalid_files -eq 0 ]; then
        print_success "All SQL files passed validation! ✓"
        exit 0
    else
        print_error "Validation failed with $invalid_files error(s)"
        exit 1
    fi
}

# Run main function
main "$@"
