# Seeds Directory

This directory contains sample data for initializing the Finance database.

## Purpose

Seed files populate the database with:
- Reference data (currencies, fiscal periods)
- Sample chart of accounts
- Test/demo data for development

## Files

1. **01_currencies.sql** - Common currency definitions
2. **02_chart_of_accounts.sql** - Sample chart of accounts structure
3. **03_fiscal_periods.sql** - Fiscal periods for the current year

## Usage

**Important**: Seeds should only be applied to development/testing environments, not production.

### Apply All Seeds

```bash
./scripts/setup.sh --with-seeds
```

### Apply Individual Seed

```bash
mysql -u root -p lumanitech_erp_finance < seeds/01_currencies.sql
mysql -u root -p lumanitech_erp_finance < seeds/02_chart_of_accounts.sql
mysql -u root -p lumanitech_erp_finance < seeds/03_fiscal_periods.sql
```

## When to Use Seeds

- **Development**: Initialize a new development database
- **Testing**: Set up test data for integration tests
- **Demo**: Populate demo environment with realistic data
- **Never**: Do NOT use in production (except reference data like currencies)

## Idempotency

Seed files use `ON DUPLICATE KEY UPDATE` or similar patterns to be idempotent:
- Running them multiple times produces the same result
- Safe to re-run during development
- Won't create duplicate records

## Customization

Organizations should:
1. Modify `02_chart_of_accounts.sql` to match their specific chart of accounts
2. Update `03_fiscal_periods.sql` for their fiscal year structure
3. Add organization-specific reference data as needed

## Production Data

For production environments:
- Load only essential reference data (currencies, etc.)
- Create production-specific chart of accounts
- Set up fiscal periods through application or admin scripts
- Never use development/test seed data
