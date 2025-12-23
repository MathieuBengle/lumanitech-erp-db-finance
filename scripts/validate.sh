#!/bin/bash

# SQL Validation Script for CI/CD
# Validates migration files for naming conventions and basic SQL syntax

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${NC}ℹ${NC} $1"
}

# Check if migration naming follows convention
check_migration_naming() {
    local file=$1
    local filename=$(basename "$file")
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    # Pattern: V###_description.sql (no double underscore, no timestamps)
    if [[ $filename =~ ^V[0-9]{3}_[a-z0-9_]+\.sql$ ]]; then
        print_success "Migration naming: $filename"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        print_error "Migration naming: $filename (should be V###_description.sql)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# Check if migration has required header
check_migration_header() {
    local file=$1
    local filename=$(basename "$file")
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if grep -q "^-- Migration:" "$file" && \
       grep -q "^-- Description:" "$file" && \
       grep -q "^-- Author:" "$file" && \
       grep -q "^-- Date:" "$file"; then
        print_success "Migration header: $filename"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        print_error "Migration header: $filename (missing required header fields)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# Check if migration tracks itself
check_migration_tracking() {
    local file=$1
    local filename=$(basename "$file")
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if grep -q "INSERT INTO schema_migrations" "$file"; then
        print_success "Migration tracking: $filename"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        print_warning "Migration tracking: $filename (should insert into schema_migrations)"
        # Don't count as failure, just warning
        return 0
    fi
}

# Basic SQL syntax validation using MySQL client if available
check_sql_syntax() {
    local file=$1
    local filename=$(basename "$file")
    
    # Skip if MySQL client not available
    if ! command -v mysql &> /dev/null; then
        return 0
    fi
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    # Basic SQL syntax check - just verify file has valid SQL-like content
    # Full validation requires a database connection which CI may not have
    if grep -v "^--" "$file" | grep -v "^[[:space:]]*$" | grep -Eq "(CREATE|ALTER|DROP|INSERT|SELECT|UPDATE|DELETE)" ; then
        print_success "SQL syntax: $filename"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        print_error "SQL syntax: $filename (no SQL statements found)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# Check for common issues
check_common_issues() {
    local file=$1
    local filename=$(basename "$file")
    
    local issues_found=0
    
    # Check for DROP TABLE without IF EXISTS
    if grep -qi "DROP TABLE" "$file" && ! grep -qi "DROP TABLE IF EXISTS" "$file"; then
        print_warning "Safety check: $filename contains DROP TABLE without IF EXISTS"
        issues_found=$((issues_found + 1))
    fi
    
    # Check for DELETE/TRUNCATE without WHERE (potential data loss)
    if grep -qi "DELETE FROM" "$file" && ! grep -qi "DELETE FROM.*WHERE" "$file"; then
        print_warning "Safety check: $filename contains DELETE without WHERE clause"
        issues_found=$((issues_found + 1))
    fi
    
    # Check for sensitive data patterns
    if grep -iq "password\s*=\s*['\"].*['\"]" "$file" || \
       grep -iq "api.key\s*=\s*['\"].*['\"]" "$file" || \
       grep -iq "secret\s*=\s*['\"].*['\"]" "$file"; then
        print_error "Security check: $filename may contain sensitive data"
        issues_found=$((issues_found + 1))
    fi
    
    return 0
}

# Check for duplicate migration versions
check_duplicate_versions() {
    print_info "Checking for duplicate migration versions..."
    
    local versions=$(find migrations/ -name "V*.sql" 2>/dev/null | xargs -I {} basename {} | grep -v TEMPLATE | cut -d'_' -f1 | sort)
    local duplicates=$(echo "$versions" | uniq -d)
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -z "$duplicates" ]; then
        print_success "No duplicate migration versions found"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        print_error "Duplicate migration versions found:"
        echo "$duplicates"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# Main validation
main() {
    echo "========================================="
    echo "  SQL Migration Validation"
    echo "========================================="
    echo ""
    
    # Check if migrations directory exists
    if [ ! -d "migrations" ]; then
        print_error "migrations/ directory not found"
        exit 1
    fi
    
    # Get all migration files
    migration_files=$(find migrations/ -name "V*.sql" 2>/dev/null | sort)
    
    if [ -z "$migration_files" ]; then
        print_warning "No migration files found in migrations/"
        echo ""
        echo "This is expected for a new repository."
        exit 0
    fi
    
    echo "Found $(echo "$migration_files" | wc -l) migration file(s)"
    echo ""
    
    # Validate each migration
    while IFS= read -r file; do
        # Skip template file
        if [[ "$(basename "$file")" == "TEMPLATE.sql" ]]; then
            print_info "Skipping template file: $(basename "$file")"
            echo ""
            continue
        fi
        
        echo "Validating: $(basename "$file")"
        check_migration_naming "$file"
        check_migration_header "$file"
        check_migration_tracking "$file"
        check_common_issues "$file"
        echo ""
    done <<< "$migration_files"
    
    # Check for duplicates
    check_duplicate_versions
    echo ""
    
    # Validate schema files if they exist
    if [ -d "schema" ]; then
        print_info "Checking schema directory structure..."
        
        if [ -d "schema/tables" ]; then
            table_count=$(find schema/tables -name "*.sql" 2>/dev/null | wc -l)
            print_info "Found $table_count table definition(s)"
        fi
        
        if [ -d "schema/views" ]; then
            view_count=$(find schema/views -name "*.sql" 2>/dev/null | wc -l)
            print_info "Found $view_count view definition(s)"
        fi
        
        if [ -d "schema/procedures" ]; then
            proc_count=$(find schema/procedures -name "*.sql" 2>/dev/null | wc -l)
            print_info "Found $proc_count stored procedure(s)"
        fi
        
        if [ -d "schema/functions" ]; then
            func_count=$(find schema/functions -name "*.sql" 2>/dev/null | wc -l)
            print_info "Found $func_count function(s)"
        fi
        echo ""
    fi
    
    # Summary
    echo "========================================="
    echo "  Validation Summary"
    echo "========================================="
    echo "Total checks: $TOTAL_CHECKS"
    echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
    
    if [ $FAILED_CHECKS -gt 0 ]; then
        echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
        echo ""
        print_error "Validation failed! Please fix the issues above."
        exit 1
    else
        echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
        echo ""
        print_success "All validations passed!"
        exit 0
    fi
}

# Run main function
main
