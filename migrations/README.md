# Migrations Directory

This directory contains versioned SQL migration scripts for the Finance database.

## Migration Strategy

This project follows a **forward-only migration strategy**:

- ✅ Migrations can only be applied forward (no rollback)
- ✅ Each migration is versioned and tracked
- ✅ Once applied, migrations should NEVER be modified
- ✅ To fix errors, create a new migration

## Naming Convention

Migration files must follow this naming pattern:
```
V###_description.sql
```

Examples:
- `V001_create_migration_tracking_table.sql`
- `V002_add_budget_tables.sql`
- `V003_add_currency_support.sql`

Where:
- **V** - Prefix indicating a versioned migration
- **###** - Zero-padded sequential number (001, 002, 003...)
- **_** - Single underscore separator
- **description** - Snake_case description of the change

## Migration File Structure

Each migration file should include:

```sql
-- ============================================================================
-- Migration: V###_description
-- Description: Detailed description of changes
-- Date: YYYY-MM-DD
-- Author: Name or System
-- ============================================================================

USE lumanitech_erp_finance;

-- Your SQL statements here

-- ============================================================================
-- Self-tracking: Record this migration
-- ============================================================================

INSERT INTO schema_migrations (version, description)
VALUES ('V###', 'description')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

## Applying Migrations

Migrations should be applied in order using the deployment script:

```bash
./scripts/deploy.sh
```

Or manually:
```bash
mysql -u root -p lumanitech_erp_finance < migrations/V001_create_migration_tracking_table.sql
mysql -u root -p lumanitech_erp_finance < migrations/V002_add_budget_tables.sql
mysql -u root -p lumanitech_erp_finance < migrations/V003_add_currency_support.sql
```

## Migration Tracking

The `schema_migrations` table tracks all applied migrations:
- Version (e.g., V001, V002, V003)
- Description
- Applied timestamp

**Standard schema:**
```sql
CREATE TABLE IF NOT EXISTS schema_migrations (
  version VARCHAR(50) PRIMARY KEY,
  description VARCHAR(255),
  applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_applied_at (applied_at)
);
```

## Best Practices

1. **Test migrations** thoroughly before applying to production
2. **Keep migrations small** and focused on a single change
3. **Use transactions** when possible (DDL in MySQL commits implicitly)
4. **Document complex changes** in comments
5. **Never modify** an applied migration - create a new one instead
6. **Include rollback notes** in comments if manual rollback is needed
7. **Verify checksums** before applying to ensure file integrity

## Creating New Migrations

1. Determine the next version number
2. Create a new file following the naming convention
3. Add the migration header with description and metadata
4. Write your SQL statements
5. Test in development environment
6. Document any dependencies or prerequisites
7. Commit to version control

## Migration Types

Common migration types:
- **Schema changes**: CREATE/ALTER/DROP tables
- **Data migrations**: INSERT/UPDATE data
- **Index changes**: CREATE/DROP indexes
- **Constraint changes**: ADD/DROP foreign keys or checks
- **Stored procedures**: CREATE/MODIFY procedures or functions

## Important Notes

- Migrations are applied by the database administrator or CI/CD pipeline
- Application code should NOT apply migrations
- Always backup before applying migrations in production
- Monitor execution time for large migrations
- Consider maintenance windows for impactful changes
