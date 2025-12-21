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
V{version}__{description}.sql
```

Examples:
- `V001__create_migration_tracking_table.sql`
- `V002__add_budget_tables.sql`
- `V003__add_currency_support.sql`

Where:
- **V** - Prefix indicating a versioned migration
- **{version}** - Zero-padded sequential number (001, 002, 003...)
- **__** - Double underscore separator
- **{description}** - Snake_case description of the change

## Migration File Structure

Each migration file should include:

```sql
-- ============================================================================
-- Migration: V{version}__{description}
-- Description: Detailed description of changes
-- Date: YYYY-MM-DD
-- Author: Name or System
-- ============================================================================

USE lumanitech_erp_finance;

-- Your SQL statements here
```

## Applying Migrations

Migrations should be applied in order using the migration script:

```bash
./scripts/migrate.sh
```

Or manually:
```bash
mysql -u root -p lumanitech_erp_finance < migrations/V001__create_migration_tracking_table.sql
mysql -u root -p lumanitech_erp_finance < migrations/V002__add_budget_tables.sql
mysql -u root -p lumanitech_erp_finance < migrations/V003__add_currency_support.sql
```

## Migration Tracking

The `schema_migrations` table tracks all applied migrations:
- Version number
- Description
- Script name
- Checksum (for verification)
- Installation timestamp
- Execution time
- Success status

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
