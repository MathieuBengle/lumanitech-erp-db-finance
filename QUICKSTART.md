# Quick Reference Guide

## Quick Commands

### Initial Setup
```bash
# Clone and setup
git clone https://github.com/MathieuBengle/lumanitech-erp-db-finance.git
cd lumanitech-erp-db-finance

# Set up MySQL login path (one-time)
mysql_config_editor set --login-path=local \
  --host=localhost \
  --user=root \
  --password

# Deploy database (schema + migrations)
./scripts/setup.sh

# Or deploy with seed data (development only)
./scripts/setup.sh --with-seeds
```

### Daily Development
```bash
# Pull latest changes
git pull

# Apply new migrations
./scripts/setup.sh

# Validate SQL before committing
./scripts/validate.sh
```

### Creating a New Migration
```bash
# 1. Determine next version number
ls migrations/ | grep "^V" | tail -1
# If last is V003, next is V004

# 2. Create migration file
cat > migrations/V004__add_your_feature.sql << 'EOFMIG'
-- ============================================================================
-- Migration: V004__add_your_feature
-- Description: Description of what this migration does
-- Date: $(date +%Y-%m-%d)
-- Author: Your Name
-- ============================================================================

USE lumanitech_erp_finance;

-- Your SQL statements here

EOFMIG

# 3. Test locally
./scripts/setup.sh

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
│   ├── setup.sh        # Single deployment script
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
3. Set up login path with `mysql_config_editor`
4. Run `./scripts/setup.sh --with-seeds`

### Updating Database Schema
1. Create new migration file (V###__description.sql)
2. Write SQL changes
3. Test locally: `./scripts/setup.sh`
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
./scripts/setup.sh --login-path=staging

# 2. Verify staging
# Test with API

# 3. Production (during maintenance window)
./scripts/setup.sh --login-path=production
```

## MySQL Login Path Management

### Setting up Login Paths

```bash
# Local development
mysql_config_editor set --login-path=local \
  --host=localhost \
  --user=root \
  --password

# Staging environment
mysql_config_editor set --login-path=staging \
  --host=staging-db.example.com \
  --user=db_user \
  --password

# Production environment
mysql_config_editor set --login-path=production \
  --host=prod-db.example.com \
  --user=db_user \
  --password
```

### Managing Login Paths

```bash
# List all login paths
mysql_config_editor print --all

# Test a login path
mysql --login-path=local -e "SELECT 1;"

# Remove a login path
mysql_config_editor remove --login-path=old_env
```

## Troubleshooting

### "MySQL client not found"
```bash
# Ubuntu/Debian
sudo apt-get install mysql-client

# macOS
brew install mysql-client
```

### "mysql_config_editor not found"
mysql_config_editor is included with MySQL client 5.6+. Install or update MySQL client.

### "Login path not found"
```bash
# Create the login path first
mysql_config_editor set --login-path=local --host=localhost --user=root --password
```

### "Permission denied" on scripts
```bash
chmod +x scripts/*.sh
```

### "Database already exists"
The deploy script will skip schema initialization and only apply migrations. This is normal.

### "Migration already applied"
This is normal - setup.sh skips already-applied migrations.

### View applied migrations
```bash
mysql --login-path=local lumanitech_erp_finance -e \
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
8. ✅ Always use mysql_config_editor for credentials

## Links to Full Documentation

- [Complete README](README.md)
- [Database Architecture](docs/ARCHITECTURE.md)
- [Schema Documentation](docs/SCHEMA.md)
- [Migration Guide](migrations/README.md)
- [CI/CD Examples](docs/CI_EXAMPLES.md)
- [Migration Checklist](docs/MIGRATION_CHECKLIST.md)
- [Scripts Documentation](scripts/README.md)
