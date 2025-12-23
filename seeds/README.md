# Seeds Directory

This directory contains SQL scripts to populate the database with initial or test data.

## Purpose

Seed data files:
- Provide sample data for local development
- Enable testing with realistic data
- Populate reference/lookup tables
- Support different environments (dev, staging, etc.)

⚠️ **Important**: Seed data is for **development and testing only**. Production data should never be committed to this repository.

## Structure

```
seeds/
└── dev/              # Development environment seed data
    ├── 01_currencies.sql
    ├── 02_chart_of_accounts.sql
    └── 03_fiscal_periods.sql
```

**Environments:**
- `dev/` - Local development and testing
- `staging/` - (Future) Staging environment data
- `test/` - (Future) Automated test data

## Usage

### Loading Seed Data

Use the deployment script with `--with-seeds` flag:

```bash
./scripts/deploy.sh --with-seeds
```

Or load manually:

```bash
# Load all dev seed data
for f in seeds/dev/*.sql; do
    echo "Loading $f"
    mysql -u root -p lumanitech_erp_finance < "$f"
done

# Load specific seed file
mysql -u root -p lumanitech_erp_finance < seeds/dev/01_currencies.sql
```

### Typical Workflow

```bash
# 1. Create fresh database and apply schema
./scripts/deploy.sh

# 2. Load seed data
./scripts/deploy.sh --with-seeds
```

## ⚠️ Production Warning

**NEVER** load development seed data into production environments. Seed data is for:
- Local development
- Testing environments  
- Demo/staging environments

Production data should be:
- Migrated from existing systems
- Entered through the application
- Loaded via approved data migration scripts

## Seed File Guidelines

### DO ✅

- Use `INSERT IGNORE` or `ON DUPLICATE KEY UPDATE` for idempotency
- Include diverse, realistic test data
- Document what the seed data represents
- Use consistent formatting
- Include data for edge cases
- Make seeds rerunnable

### DON'T ❌

- Include real customer data
- Include sensitive information (passwords, keys, PII)
- Include production data
- Make seeds environment-dependent
- Use absolute values for timestamps (use CURRENT_TIMESTAMP or relative dates)

## Seed File Format

```sql
-- ============================================================================
-- Seed: Description of seed data
-- Environment: dev
-- ============================================================================

USE lumanitech_erp_finance;

-- Use INSERT IGNORE for idempotency
INSERT IGNORE INTO table_name (id, name, status) VALUES
(1, 'Example 1', 'active'),
(2, 'Example 2', 'active'),
(3, 'Example 3', 'inactive');
```

## Current Seed Files

### dev/01_currencies.sql

Provides common currency definitions including:
- USD (US Dollar)
- EUR (Euro)
- CAD (Canadian Dollar)
- GBP (British Pound)
- JPY (Japanese Yen)

### dev/02_chart_of_accounts.sql

Provides sample chart of accounts with:
- Asset accounts
- Liability accounts
- Equity accounts
- Revenue accounts
- Expense accounts

### dev/03_fiscal_periods.sql

Provides fiscal period definitions for testing.

## Idempotency Strategies

### Using INSERT IGNORE

```sql
INSERT IGNORE INTO currencies (currency_code, currency_name)
VALUES ('USD', 'US Dollar');
```

### Using ON DUPLICATE KEY UPDATE

```sql
INSERT INTO currencies (currency_code, currency_name)
VALUES ('USD', 'US Dollar')
ON DUPLICATE KEY UPDATE currency_name = currency_name;
```

## Data Privacy

**NEVER** include:
- Real customer names, emails, or phone numbers
- Actual tax IDs or government identifiers
- Real payment information
- Production passwords or API keys
- Personal Identifiable Information (PII)

Use:
- Fake but realistic data
- Example.com domain emails
- Placeholder values
- Generic company names
- Test account codes

## Maintenance

Regularly review and update seed data to:
- Add new test scenarios
- Include examples of new features
- Remove obsolete data
- Ensure data remains realistic
- Update for schema changes
