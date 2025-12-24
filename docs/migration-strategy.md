# Migration Strategy

## Overview

This document describes the migration strategy for the Finance database (`lumanitech_erp_finance`).

## Migration Naming Convention

All migrations follow the pattern: `V###_description.sql`

- `V###`: Version number (V000, V001, V002, etc.)
- `_`: Single underscore separator
- `description`: Brief, snake_case description

Examples:
- `V000_create_schema_migrations_table.sql`
- `V001_add_budget_tables.sql`
- `V002_add_currency_support.sql`

## Migration Principles

1. **Forward-only**: Migrations are never rolled back
2. **Immutable**: Once applied, migrations cannot be modified
3. **Sequential**: Migrations are applied in version order
4. **Self-tracking**: Each migration records itself in `schema_migrations`

## Migration Template

Use `migrations/TEMPLATE.sql` as the starting point for new migrations:

```sql
-- =============================================================================
-- Migration: V###_description
-- Description: What this migration does
-- Author: Your Name
-- Date: YYYY-MM-DD
-- =============================================================================

USE lumanitech_erp_finance;

-- Your SQL changes here

-- =============================================================================
-- Migration Tracking
-- =============================================================================
INSERT INTO schema_migrations (version, description)
VALUES ('V###', 'description')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

## Creating a New Migration

1. Determine the next version number:
   ```bash
   ls migrations/V*.sql | sort -V | tail -1
   ```

2. Copy the template:
   ```bash
   cp migrations/TEMPLATE.sql migrations/V00X_your_description.sql
   ```

3. Update the header and add your changes

4. Test locally:
   ```bash
   ./scripts/test-migrations.sh
   ```

5. Validate:
   ```bash
   ./scripts/validate.sh
   ```

## Migration Execution

Migrations are executed by the `apply-migrations.sh` script in version order. The script:
- Checks which migrations have been applied
- Applies pending migrations in order
- Records each successful migration in `schema_migrations`

## Best Practices

- Keep migrations small and focused
- Use idempotent SQL when possible (`IF NOT EXISTS`, etc.)
- Test migrations on a copy of production data
- Document complex changes
- Coordinate breaking changes with the Finance API team

## Rollback Strategy

Since we use forward-only migrations, rollbacks are handled by creating a new migration that reverses the changes.

Example:
- V003 adds a column
- V004 removes that column (if needed)
