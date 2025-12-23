# Migration Strategy

## Overview

This repository implements a **forward-only migration strategy** for database schema management. This approach ensures consistency, traceability, and safety across all environments.

## Core Principles

### 1. Forward-Only Migrations

**Never modify or delete existing migrations.** Once a migration file is committed to the repository, it is immutable.

**Why?**
- Different environments may be at different migration states
- Modifying existing migrations can cause inconsistencies
- Historical record of all schema changes is preserved
- Prevents accidental data loss

### 2. Versioned Sequential Naming

All migrations follow this naming convention:
```
V###_description.sql
```

**Components:**
- `V###`: Version number with zero-padded sequential number (V001, V002, V003, ...)
- `_`: Single underscore separator
- `description`: Brief, lowercase, snake_case description of the change

**Examples:**
- `V001_create_migration_tracking_table.sql`
- `V002_add_budget_tables.sql`
- `V003_add_currency_support.sql`

### 3. Idempotency

Migrations should be idempotent whenever possible, meaning they can be safely run multiple times without causing errors or unintended side effects.

**Techniques:**
```sql
-- Tables
CREATE TABLE IF NOT EXISTS table_name (...);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_name ON table_name(column);

-- Columns (MySQL 8.0.29+)
ALTER TABLE table_name 
ADD COLUMN IF NOT EXISTS column_name VARCHAR(255);

-- For older MySQL versions, check before adding:
SELECT COUNT(*) INTO @col_exists
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'table_name' 
AND COLUMN_NAME = 'column_name';

SET @sql = IF(@col_exists = 0, 
  'ALTER TABLE table_name ADD COLUMN column_name VARCHAR(255)', 
  'SELECT "Column already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
```

### 4. Self-Tracking

Each migration records itself in the `schema_migrations` table:

```sql
INSERT INTO schema_migrations (version, description) 
VALUES ('V001', 'create_migration_tracking_table')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

**schema_migrations table structure:**
```sql
CREATE TABLE IF NOT EXISTS schema_migrations (
  version VARCHAR(50) PRIMARY KEY,
  description VARCHAR(255),
  applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_applied_at (applied_at)
);
```

### 5. Rollback via Forward Migration

To undo changes, create a new migration that reverses the previous one:

```sql
-- Original: V003_add_notes_column.sql
ALTER TABLE accounts ADD COLUMN notes TEXT;

-- Rollback: V004_remove_notes_column.sql
ALTER TABLE accounts DROP COLUMN IF EXISTS notes;
```

## Migration Workflow

### Creating a New Migration

1. **Determine next version number:**
   ```bash
   ls migrations/ | grep "^V" | sort -V | tail -1
   # Output: V003_add_currency_support.sql
   # Next version: V004
   ```

2. **Create migration file:**
   ```bash
   cp migrations/TEMPLATE.sql migrations/V004_your_description.sql
   ```

3. **Write migration following the template:**
   ```sql
   -- ============================================================================
   -- Migration: V004_your_description
   -- Description: Detailed description of what this migration does
   -- Date: 2025-12-23
   -- Author: Your Name
   -- ============================================================================
   
   USE lumanitech_erp_finance;
   
   -- Your SQL here
   CREATE TABLE IF NOT EXISTS example_table (
       id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
       name VARCHAR(255) NOT NULL,
       created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       PRIMARY KEY (id)
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
   
   -- ============================================================================
   -- Self-tracking: Record this migration
   -- ============================================================================
   
   INSERT INTO schema_migrations (version, description)
   VALUES ('V004', 'your_description')
   ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
   
   -- ============================================================================
   -- Rollback Notes (for reference only - not executed)
   -- ============================================================================
   -- To manually rollback this migration:
   -- DROP TABLE IF EXISTS example_table;
   -- DELETE FROM schema_migrations WHERE version = 'V004';
   ```

4. **Test locally:**
   ```bash
   mysql -u root -p lumanitech_erp_finance < migrations/V004_your_description.sql
   ```

5. **Validate:**
   ```bash
   ./scripts/validate.sh
   ```

6. **Commit and push:**
   ```bash
   git add migrations/V004_your_description.sql
   git commit -m "Add migration V004: your_description"
   git push
   ```

### Migration Execution

Migrations are executed during deployment:

1. Deployment script connects to database
2. Checks `schema_migrations` table for applied migrations
3. Identifies unapplied migrations (sorted alphabetically)
4. Executes each migration in order
5. Each migration records itself in `schema_migrations`
6. Reports any failures

### Manual Execution (Development)

For local testing:

```bash
# Deploy all (uses deployment script)
./scripts/deploy.sh

# Apply specific migration
mysql -u root -p lumanitech_erp_finance < migrations/V004_your_description.sql

# Check applied migrations
mysql -u root -p lumanitech_erp_finance -e "SELECT * FROM schema_migrations ORDER BY version;"
```

## Best Practices

### DO ✅

- **Use descriptive names**: `add_payment_methods` not `update_transactions`
- **Keep migrations small**: One logical change per migration
- **Test on production-like data**: Use anonymized production dumps
- **Include rollback comments**: Document how to reverse the change
- **Use transactions when appropriate**:
  ```sql
  START TRANSACTION;
  -- Your changes
  COMMIT;
  ```
- **Add comments**: Explain complex logic or business rules
- **Check for existence**: Use `IF NOT EXISTS` / `IF EXISTS`
- **Handle dependencies**: Ensure referenced tables/columns exist

### DON'T ❌

- **Never modify existing migrations**: Create new ones instead
- **Never delete migrations**: They are historical records
- **Avoid breaking changes without coordination**: 
  - Renaming columns (use new column + deprecation period)
  - Changing data types incompatibly
  - Dropping tables with data
- **Don't commit sensitive data**: No passwords, API keys, or real user data
- **Don't use database-specific features unnecessarily**: Stick to standard SQL when possible
- **Avoid long-running migrations in production**: Split into smaller chunks

## Common Patterns

### Adding a Table

```sql
-- Migration: V004_add_payment_methods.sql
CREATE TABLE IF NOT EXISTS payment_methods (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  method_code VARCHAR(50) NOT NULL,
  method_name VARCHAR(255) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  PRIMARY KEY (id),
  UNIQUE KEY uk_method_code (method_code),
  KEY idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_migrations (version, description) 
VALUES ('V004', 'add_payment_methods')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

### Adding a Column

```sql
-- Migration: V005_add_notes_to_transactions.sql
ALTER TABLE transactions 
ADD COLUMN IF NOT EXISTS notes TEXT
COMMENT 'Additional notes for this transaction';

INSERT INTO schema_migrations (version, description) 
VALUES ('V005', 'add_notes_to_transactions')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

### Adding an Index

```sql
-- Migration: V006_add_index_transaction_date.sql
CREATE INDEX IF NOT EXISTS idx_transactions_date 
ON transactions(transaction_date);

INSERT INTO schema_migrations (version, description) 
VALUES ('V006', 'add_index_transaction_date')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

### Modifying Column (Safe Pattern)

```sql
-- Migration: V007_extend_account_code_length.sql
-- Extending VARCHAR is generally safe (does not require table rebuild in MySQL 5.7+)
ALTER TABLE accounts 
MODIFY COLUMN account_code VARCHAR(100) NOT NULL 
COMMENT 'Unique account code/reference';

INSERT INTO schema_migrations (version, description) 
VALUES ('V007', 'extend_account_code_length')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

### Data Migration

```sql
-- Migration: V008_populate_default_currency.sql
-- Set default currency for existing transactions without one
UPDATE transactions 
SET currency_id = (SELECT id FROM currencies WHERE currency_code = 'USD' LIMIT 1)
WHERE currency_id IS NULL;

INSERT INTO schema_migrations (version, description) 
VALUES ('V008', 'populate_default_currency')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

### Creating a View

```sql
-- Migration: V009_create_active_accounts_view.sql
CREATE OR REPLACE VIEW active_accounts AS
SELECT id, account_code, account_name, account_type
FROM accounts
WHERE is_active = TRUE;

INSERT INTO schema_migrations (version, description) 
VALUES ('V009', 'create_active_accounts_view')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

## Handling Failures

### If a Migration Fails in Development

1. Fix the issue in the migration file (only if not yet committed)
2. Drop the partially applied changes manually
3. Delete the migration record if it was inserted:
   ```sql
   DELETE FROM schema_migrations WHERE version = 'V004';
   ```
4. Re-run the migration
5. Test thoroughly

### If a Migration Fails in Production

1. **Immediate response:**
   - Check `schema_migrations` to see what was applied
   - Assess impact on application
   - Determine if rollback is needed

2. **Rollback options:**
   - Create a new migration that reverses the change
   - Apply manually if urgent (document in migration later)

3. **Post-incident:**
   - Create migration documenting manual changes
   - Update migration to be more robust
   - Add better error handling

## Migration Review Checklist

Before merging a migration:

- [ ] Version number is correct and sequential
- [ ] Description is clear and accurate
- [ ] Migration is idempotent (when possible)
- [ ] Tested on local development database
- [ ] Tested on database with existing data
- [ ] Self-tracking INSERT statement included
- [ ] Rollback instructions documented in comments
- [ ] No sensitive data included
- [ ] Passes `./scripts/validate.sh`
- [ ] Breaking changes are coordinated with API team
- [ ] Performance impact considered for large tables

## FAQ

### Q: Can I modify a migration after it's been merged?

**A: No.** Once merged, migrations are immutable. Create a new migration to make changes.

### Q: How do I handle merge conflicts in migration versions?

**A: Coordinate with your team.** If two migrations have the same version number, one must be renumbered to the next available version. Update both the filename and the version in the SQL.

### Q: What if I need to rollback a migration?

**A: Create a new migration** that reverses the changes. Document it clearly.

### Q: Can migrations contain data?

**A: Yes,** for reference data, configuration, or data migrations. Never include sensitive or user-specific data.

### Q: How do I test migrations with large datasets?

**A: Use anonymized production dumps** in a staging environment. Test for performance and correctness.

### Q: What about schema.sql files?

**A: They are reference only** showing current state. Migrations are the source of truth for schema evolution.

## Version Control

- All migrations must be committed to version control
- Never commit directly to main/master
- Create feature branch for new migrations
- Require pull request review before merging
- Tag releases with applied migrations

## References

- [MySQL ALTER TABLE Documentation](https://dev.mysql.com/doc/refman/8.0/en/alter-table.html)
- [MySQL Data Types](https://dev.mysql.com/doc/refman/8.0/en/data-types.html)
- [Database Migration Best Practices](https://www.liquibase.org/get-started/best-practices)
