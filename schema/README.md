# Schema Directory

This directory contains the base database schema (DDL) for the Finance module.

## Structure

The schema is organized into subdirectories:

```
schema/
├── 01_create_database.sql  # Database creation
├── tables/                 # Table definitions
├── views/                  # View definitions
├── procedures/             # Stored procedures
├── functions/              # User-defined functions
├── triggers/               # Database triggers
└── indexes/                # Index definitions
```

## Purpose

These files represent the **current state** of the database schema. They are used:
- For initial database setup
- As reference documentation
- For development environments

⚠️ **Important**: For schema evolution, always use **migrations** (see `/migrations`), not direct modification of these files.

## Initial Setup

The deployment script applies schema files in this order:
1. Database creation (`01_create_database.sql`)
2. Tables (from `tables/` directory)
3. Views (from `views/` directory)
4. Procedures (from `procedures/` directory)
5. Functions (from `functions/` directory)
6. Triggers (from `triggers/` directory)
7. Indexes (from `indexes/` directory)

Then it applies migrations from `/migrations`.

## Modifying Schema

**DO NOT** modify these files directly for production changes.

Instead:
1. Create a migration in `/migrations`
2. Test the migration
3. Apply it via deployment script
4. Optionally update schema files to reflect current state (for documentation)

## Files

### 01_create_database.sql

Creates the database with proper character set and collation:
```sql
CREATE DATABASE IF NOT EXISTS lumanitech_erp_finance
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE lumanitech_erp_finance;
```

### tables/

Contains the table definitions:
- `02_accounts.sql` - Chart of accounts
- `03_transactions.sql` - Financial transactions
- `04_transaction_lines.sql` - Transaction line items
- `05_fiscal_periods.sql` - Fiscal periods

### views/

Reserved for view definitions (currently empty).

### procedures/

Reserved for stored procedures (currently empty).

### functions/

Reserved for user-defined functions (currently empty).

### triggers/

Reserved for database triggers (currently empty).

### indexes/

Reserved for additional index definitions (currently empty).

## Usage

Apply schema during initial setup:
```bash
./scripts/deploy.sh
```

Or manually:
```bash
# Create database
mysql -u root -p < schema/01_create_database.sql

# Apply tables
for f in schema/tables/*.sql; do
    mysql -u root -p lumanitech_erp_finance < "$f"
done

# Apply views, procedures, functions, triggers, indexes
# (similar pattern for each subdirectory)
```
