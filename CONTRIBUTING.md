# Contributing to Lumanitech ERP Finance Database

Thank you for contributing to the Finance database repository! This guide will help you make successful contributions.

## Getting Started

1. **Read the documentation:**
   - [README.md](README.md) - Overview and setup
   - [docs/migration-strategy.md](docs/migration-strategy.md) - Migration best practices
   - [docs/schema.md](docs/schema.md) - Current schema documentation

2. **Set up your local environment:**
   ```bash
   # Clone repository
   git clone <repository-url>
   cd lumanitech-erp-db-finance
   
   # Create local database
   mysql -u root -p -e "CREATE DATABASE lumanitech_erp_finance CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
   
   # Apply migrations
   ./scripts/deploy.sh --with-seeds
   ```

## Making Changes

### Before You Start

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-change-description
   ```

2. **Understand the change:**
   - Is this a new table, column, index, or view?
   - Does it affect existing data?
   - Is it a breaking change?
   - Have you coordinated with the API team?

### Creating a Migration

1. **Determine next version:**
   ```bash
   ls migrations/ | grep "^V" | sort -V | tail -1
   # If last is V003, next is V004
   ```

2. **Create migration file:**
   ```bash
   cp migrations/TEMPLATE.sql migrations/V004_your_description.sql
   ```

3. **Edit the migration:**
   - Update header (version, description, author, date)
   - Write your SQL changes
   - Use idempotent patterns (IF NOT EXISTS, IF EXISTS)
   - Update self-tracking INSERT statement
   - Document rollback in comments

4. **Test locally:**
   ```bash
   # Apply your migration
   mysql -u root -p lumanitech_erp_finance < migrations/V004_your_description.sql
   
   # Verify changes
   mysql -u root -p lumanitech_erp_finance -e "SHOW TABLES;"
   mysql -u root -p lumanitech_erp_finance -e "DESCRIBE table_name;"
   
   # Test idempotency (run again)
   mysql -u root -p lumanitech_erp_finance < migrations/V004_your_description.sql
   ```

5. **Update schema files (if major change):**
   ```bash
   # For new tables or significant changes
   mysqldump -u root -p --no-data --skip-add-drop-table lumanitech_erp_finance table_name > schema/tables/new_table.sql
   ```

6. **Run validation:**
   ```bash
   ./scripts/validate.sh
   ```

### Creating Seed Data

1. **Create seed file:**
   ```bash
   touch seeds/dev/new_seed.sql
   ```

2. **Write idempotent SQL:**
   ```sql
   -- Use INSERT IGNORE or ON DUPLICATE KEY UPDATE
   INSERT IGNORE INTO table_name (id, name) VALUES
   (1, 'Test Data');
   
   -- Verify
   SELECT COUNT(*) FROM table_name;
   ```

3. **Test:**
   ```bash
   mysql -u root -p lumanitech_erp_finance < seeds/dev/new_seed.sql
   # Run again to verify idempotency
   mysql -u root -p lumanitech_erp_finance < seeds/dev/new_seed.sql
   ```

## Code Review Process

### Before Submitting

- [ ] Migration naming follows convention: `V###_description.sql`
- [ ] Migration has required header fields
- [ ] SQL is idempotent where possible
- [ ] Tested locally on fresh database
- [ ] Tested locally on database with existing data
- [ ] Validation script passes: `./scripts/validate.sh`
- [ ] No sensitive data included
- [ ] Schema documentation updated (if needed)
- [ ] Coordinated with API team for breaking changes

### Submitting Pull Request

1. **Commit your changes:**
   ```bash
   git add migrations/V004_your_description.sql
   git commit -m "Add migration V004: your_description"
   git push origin feature/your-change-description
   ```

2. **Create pull request:**
   - Clear title describing the change
   - Description explaining WHY the change is needed
   - Reference any related issues
   - Tag relevant reviewers

3. **PR description template:**
   ```markdown
   ## Description
   Brief description of what this migration does.
   
   ## Motivation
   Why is this change needed?
   
   ## Changes
   - List of specific changes
   - Tables/columns affected
   
   ## Testing
   - [ ] Tested on fresh database
   - [ ] Tested on database with existing data
   - [ ] Validation script passes
   
   ## Breaking Changes
   None / List any breaking changes
   
   ## Rollback Plan
   Describe how to rollback if needed (usually via new migration)
   ```

### Review Process

1. Automated CI checks will run validation script
2. Code review by database team
3. API team approval for breaking changes
4. Merge to main branch
5. Automatic deployment in next release

## Best Practices

### SQL Style

```sql
-- Use uppercase for SQL keywords
CREATE TABLE accounts (
    -- Lowercase for identifiers
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Indent nested queries
SELECT a.id, a.name
FROM accounts a
WHERE a.status IN (
    SELECT DISTINCT status
    FROM active_statuses
);

-- One column per line for readability
INSERT INTO accounts (
    account_code,
    account_name,
    status
) VALUES (
    '1100',
    'Cash',
    'active'
);
```

### Naming Conventions

- **Tables**: lowercase, plural (e.g., `accounts`, `transactions`)
- **Columns**: lowercase, snake_case (e.g., `account_name`, `created_at`)
- **Indexes**: `idx_tablename_columnname` (e.g., `idx_accounts_code`)
- **Foreign keys**: `fk_tablename_columnname` (e.g., `fk_transactions_account_id`)
- **Views**: lowercase, descriptive (e.g., `active_accounts`)
- **Procedures**: lowercase, verb_noun (e.g., `update_account_balance`)

### Common Patterns

#### Adding a Column (Safe)

```sql
ALTER TABLE accounts 
ADD COLUMN IF NOT EXISTS phone VARCHAR(50) NULL 
COMMENT 'Primary phone number';
```

#### Adding an Index

```sql
CREATE INDEX IF NOT EXISTS idx_accounts_code 
ON accounts(account_code);
```

#### Modifying Column (Safe - Extending)

```sql
-- Safe: Extending VARCHAR
ALTER TABLE accounts 
MODIFY COLUMN account_code VARCHAR(100) NOT NULL;
```

#### Modifying Column (Unsafe - Breaking)

```sql
-- Unsafe: Shortening VARCHAR or changing type
-- Requires data validation first
ALTER TABLE accounts 
MODIFY COLUMN account_code VARCHAR(20) NOT NULL;
```

#### Renaming Column (Breaking - Requires Coordination)

```sql
-- Step 1: Add new column
ALTER TABLE accounts 
ADD COLUMN account_name VARCHAR(255) NULL;

-- Step 2: Copy data (new migration)
UPDATE accounts SET account_name = name;

-- Step 3: Drop old column (new migration after API update)
ALTER TABLE accounts DROP COLUMN name;
```

## Troubleshooting

### Validation Fails

```bash
# Run validation to see errors
./scripts/validate.sh

# Common issues:
# - Wrong naming format
# - Missing header fields
# - Missing self-tracking INSERT
```

### Migration Fails Locally

```bash
# Check current state
mysql -u root -p lumanitech_erp_finance -e "SELECT * FROM schema_migrations ORDER BY version;"

# Drop and recreate database
mysql -u root -p -e "DROP DATABASE IF EXISTS lumanitech_erp_finance;"
./scripts/deploy.sh --with-seeds
```

### Merge Conflicts

If two migrations have the same version number:

1. Regenerate version number for your migration:
   ```bash
   # Get next available version
   ls migrations/ | grep "^V" | sort -V | tail -1
   ```

2. Rename file and update version in SQL

3. Resolve conflict

## Getting Help

- **Questions**: Open an issue or discussion
- **Bugs**: Open an issue with reproduction steps
- **API Coordination**: Contact the Finance API team
- **Emergency**: Contact database administrator

## Code of Conduct

- Be respectful and professional
- Test thoroughly before submitting
- Document complex changes
- Ask questions if unsure
- Never commit sensitive data
- Follow security best practices

## License

Internal use only - Lumanitech ERP System
