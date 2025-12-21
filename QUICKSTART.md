# Quick Reference Guide

## Quick Commands

### Initial Setup
```bash
# Clone and setup
git clone https://github.com/MathieuBengle/lumanitech-erp-db-finance.git
cd lumanitech-erp-db-finance

# Initialize database (one-time)
export MYSQL_PASSWORD=your_password
./scripts/init_schema.sh
./scripts/migrate.sh
./scripts/seed.sh  # Development only
```

### Daily Development
```bash
# Pull latest changes
git pull

# Apply new migrations
./scripts/migrate.sh

# Validate SQL before committing
./scripts/validate.sh
```

### Creating a New Migration
```bash
# 1. Determine next version number
ls migrations/ | grep "^V" | tail -1
# If last is V003, next is V004

# 2. Create migration file
cat > migrations/V004__add_your_feature.sql << 'EOF'
-- ============================================================================
-- Migration: V004__add_your_feature
-- Description: Description of what this migration does
-- Date: $(date +%Y-%m-%d)
-- Author: Your Name
-- ============================================================================

USE lumanitech_erp_finance;

-- Your SQL statements here

EOF

# 3. Test locally
./scripts/migrate.sh

# 4. Validate
./scripts/validate.sh

# 5. Commit
git add migrations/V004__add_your_feature.sql
git commit -m "Add migration: add your feature"
git push
```

## Directory Quick Reference

```
.
├── schema/          # Base schema (initial structure)
├── migrations/      # Versioned changes (V001, V002, etc.)
├── seeds/           # Sample data (dev/test only)
├── scripts/         # Management scripts
│   ├── init_schema.sh   # Create database
│   ├── migrate.sh       # Apply migrations
│   ├── seed.sh          # Load seeds
│   └── validate.sh      # Validate SQL
└── docs/            # Documentation
    ├── ARCHITECTURE.md  # Design & ownership
    ├── SCHEMA.md        # Table reference
    └── CI_EXAMPLES.md   # CI/CD examples
```

## Common Workflows

### New Developer Onboarding
1. Install MySQL client
2. Clone repository
3. Set MYSQL_PASSWORD
4. Run init_schema.sh
5. Run migrate.sh
6. Run seed.sh (dev data)

### Updating Database Schema
1. Create new migration file (V###__description.sql)
2. Write SQL changes
3. Test locally: `./scripts/migrate.sh`
4. Validate: `./scripts/validate.sh`
5. Commit and push
6. CI validates automatically

### Pre-Commit Checklist
- [ ] Validated SQL: `./scripts/validate.sh`
- [ ] Tested migration locally
- [ ] Migration naming follows convention
- [ ] No sensitive data in files
- [ ] Documentation updated (if needed)

### Deployment Process
```bash
# 1. Staging
export MYSQL_PASSWORD=$STAGING_PASSWORD
./scripts/migrate.sh

# 2. Verify staging
# Test with API

# 3. Production (during maintenance window)
export MYSQL_PASSWORD=$PROD_PASSWORD
./scripts/migrate.sh
```

## Environment Variables

```bash
# Set these in your environment or CI/CD
export MYSQL_USER=root              # Default: root
export MYSQL_PASSWORD=your_password # Required
export DB_NAME=lumanitech_erp_finance # Default (optional)
```

## Troubleshooting

### "MySQL client not found"
```bash
# Ubuntu/Debian
sudo apt-get install mysql-client

# macOS
brew install mysql-client
```

### "Permission denied" on scripts
```bash
chmod +x scripts/*.sh
```

### "Database does not exist"
```bash
# Run schema initialization first
./scripts/init_schema.sh
```

### "Migration already applied"
```bash
# This is normal - migrations are idempotent
# Script will skip already-applied migrations
```

### View applied migrations
```bash
mysql -u root -p lumanitech_erp_finance -e \
  "SELECT version, description, installed_on FROM schema_migrations ORDER BY id;"
```

## File Naming Conventions

### Migrations
- Format: `V###__description.sql`
- Example: `V001__create_migration_tracking_table.sql`
- Version: Zero-padded numbers (001, 002, 003...)
- Description: Lowercase with underscores

### Schema Files
- Format: `##_description.sql`
- Example: `01_create_database.sql`
- Order: Numeric prefix determines execution order

### Seed Files
- Format: `##_description.sql`
- Example: `01_currencies.sql`
- Order: Numeric prefix determines execution order

## Important Rules

1. ❌ Never modify existing migrations
2. ✅ Always create new migration for changes
3. ❌ Never commit database credentials
4. ✅ Always validate before committing
5. ❌ Never apply seeds to production
6. ✅ Always test migrations locally first
7. ❌ Never use rollback (forward-only)
8. ✅ Always backup before production migration

## Links to Full Documentation

- [Complete README](README.md)
- [Database Architecture](docs/ARCHITECTURE.md)
- [Schema Documentation](docs/SCHEMA.md)
- [Migration Guide](migrations/README.md)
- [CI/CD Examples](docs/CI_EXAMPLES.md)
- [Migration Checklist](docs/MIGRATION_CHECKLIST.md)
