# Schema Directory

This directory contains the base database schema definitions for the Finance module.

## Files

The schema files should be executed in numerical order:

1. **01_create_database.sql** - Creates the database with proper character set
2. **02_accounts.sql** - Chart of accounts table
3. **03_transactions.sql** - Financial transactions table
4. **04_transaction_lines.sql** - Transaction line items (debits/credits)
5. **05_fiscal_periods.sql** - Fiscal periods for reporting

## Usage

To create the schema from scratch:

```bash
mysql -u root -p < schema/01_create_database.sql
mysql -u root -p lumanitech_erp_finance < schema/02_accounts.sql
mysql -u root -p lumanitech_erp_finance < schema/03_transactions.sql
mysql -u root -p lumanitech_erp_finance < schema/04_transaction_lines.sql
mysql -u root -p lumanitech_erp_finance < schema/05_fiscal_periods.sql
```

Or use the provided script:
```bash
./scripts/init_schema.sh
```

## Notes

- These files represent the initial schema and should not be modified after deployment
- All changes should be made through migrations in the `/migrations` directory
- Foreign key constraints ensure referential integrity
- All tables use InnoDB engine for transaction support
- Character set is utf8mb4 for full Unicode support
