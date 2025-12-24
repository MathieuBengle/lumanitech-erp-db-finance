#!/bin/bash
# =============================================================================
# Script: validate.sh
# Description: Run all validation checks on Finance database
# Usage: ./validate.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==============================================================================${NC}"
echo -e "${BLUE}Finance Database Validation${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""

ERRORS=0

# Step 1: Validate SQL syntax
echo -e "${BLUE}Step 1: Validating SQL syntax...${NC}"
if "$SCRIPT_DIR/validate-sql-syntax.sh"; then
    echo -e "${GREEN}✓ SQL syntax validation passed${NC}"
else
    echo -e "${RED}✗ SQL syntax validation failed${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Step 2: Validate migrations
echo -e "${BLUE}Step 2: Validating migrations...${NC}"
if "$SCRIPT_DIR/validate-migrations.sh"; then
    echo -e "${GREEN}✓ Migration validation passed${NC}"
else
    echo -e "${RED}✗ Migration validation failed${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Step 3: Validate schema structure
echo -e "${BLUE}Step 3: Validating schema structure...${NC}"
schema_dir="$PROJECT_ROOT/schema"

# Check required directories
for dir in tables views procedures functions triggers indexes; do
    if [ -d "$schema_dir/$dir" ]; then
        echo -e "${GREEN}✓${NC} $dir/ directory exists"
    else
        echo -e "${RED}✗${NC} $dir/ directory missing"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# Step 4: Validate seeds structure
echo -e "${BLUE}Step 4: Validating seeds structure...${NC}"
seeds_dir="$PROJECT_ROOT/seeds"

if [ -d "$seeds_dir/dev" ]; then
    echo -e "${GREEN}✓${NC} seeds/dev/ directory exists"
else
    echo -e "${RED}✗${NC} seeds/dev/ directory missing"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Step 5: Validate schema file naming
echo -e "${BLUE}Step 5: Validate schema file naming...${NC}"

check_dir="$schema_dir/procedures"
if [[ -d "$check_dir" ]]; then
    for f in "$check_dir"/*.sql; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f")
        if [[ ! "$name" =~ ^sp_[a-z0-9_]+\.sql$ ]]; then
            echo -e "${RED}✗ Invalid procedure filename: $name (expected sp_name.sql)${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${GREEN}✓${NC} $name"
        fi
    done
fi

check_dir="$schema_dir/triggers"
if [[ -d "$check_dir" ]]; then
    for f in "$check_dir"/*.sql; do
        [[ -f "$f" ]] || continue
        name=$(basename "$f")
        if [[ ! "$name" =~ ^trg_[a-z0-9_]+\.sql$ ]]; then
            echo -e "${RED}✗ Invalid trigger filename: $name (expected trg_name.sql)${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${GREEN}✓${NC} $name"
        fi
    done
fi
echo ""

# Summary
echo -e "${BLUE}==============================================================================${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All validation checks passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s)${NC}"
    exit 1
fi
