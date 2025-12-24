# Lumanitech ERP - Finance Database

This repository contains the MySQL database schema, migrations, and seed data for the Finance module of the Lumanitech ERP system.

## Overview

This is a **SQL-only repository** containing database definitions and migration scripts. No application code is included here.

## Ownership

This database is **owned and managed by the Finance API**. The API service is responsible for:
- Executing migrations during deployment
- Managing database schema changes
- Ensuring data integrity and consistency

⚠️ **Important**: Direct database modifications outside of the migration system are not permitted. All schema changes must be made through versioned migration scripts.

## Repository Structure

```
.
├── schema/              # Current database schema (DDL)
│   ├── 01_create_database.sql
│   ├── tables/         # Table definitions
│   ├── views/          # View definitions
│   ├── procedures/     # Stored procedures
│   ├── functions/      # User-defined functions
│   ├── triggers/       # Database triggers
│   └── indexes/        # Index definitions
├── migrations/         # Versioned migration scripts
│   ├── TEMPLATE.sql
│   ├── V001_create_migration_tracking_table.sql
│   ├── V002_add_budget_tables.sql
│   └── V003_add_currency_support.sql
├── seeds/              # Seed data for development/testing
│   ├── README.md
│   └── dev/           # Development seed data
│       ├── 01_currencies.sql
│       ├── 02_chart_of_accounts.sql
│       └── 03_fiscal_periods.sql
├── docs/               # Documentation
│   ├── migration-strategy.md
│   └── schema.md
└── scripts/            # CI/CD validation scripts
    ├── deploy.sh
    ├── validate.sh
    └── README.md
```

## Migration Strategy

This repository follows a **forward-only migration** strategy:

### Principles

1. **Never modify existing migrations** - Once a migration is committed, it should never be changed
2. **Always create new migrations** - To fix issues, create a new migration that corrects the problem
3. **Sequential versioning** - Migrations are named: `V###_description.sql`
4. **Idempotent when possible** - Migrations should check for existence before creating objects
5. **Rollback via new migrations** - To undo changes, create a new migration that reverses them

### Migration Naming Convention

```
V###_description.sql
```

Examples:
- `V001_create_migration_tracking_table.sql`
- `V002_add_budget_tables.sql`
- `V003_add_currency_support.sql`

### Creating a Migration

1. Determine next version: `ls migrations/ | grep "^V" | sort -V | tail -1`
2. Create file: `cp migrations/TEMPLATE.sql migrations/V004_your_description.sql`
3. Write SQL with proper guards:

```sql
-- ============================================================================
-- Migration: V004_your_description
-- Description: Brief description of what this migration does
-- Author: Your Name
-- Date: YYYY-MM-DD
-- ============================================================================

USE lumanitech_erp_finance;

-- Your SQL statements here
CREATE TABLE IF NOT EXISTS example_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- ============================================================================
-- Self-tracking: Record this migration
-- ============================================================================

INSERT INTO schema_migrations (version, description)
VALUES ('V004', 'your_description')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
```

4. Test locally
5. Commit and push

### Migration Execution Order

Migrations are executed in alphabetical order (version numbers ensure chronological order).
The deployment script tracks which migrations have been applied using a `schema_migrations` table.

## Seed Data

The `seeds/` directory contains SQL scripts to populate the database with initial or test data:

- `seeds/dev/` - Development environment data
- Use seed data for local development and testing
- Seed scripts should be idempotent (safe to run multiple times)

## CI/CD Validation

The `scripts/validate.sh` script validates SQL syntax and migration naming conventions.
This script runs automatically in CI/CD pipelines before merging.

### Running Validation Locally

```bash
./scripts/validate.sh
```

## Getting Started

### Prerequisites

- MySQL 8.0+
- Access to the target database environment

### Local Development

1. Clone this repository:
```bash
git clone <repository-url>
cd lumanitech-erp-db-finance
```

2. Make the deployment script executable (required once):
```bash
chmod +x ./scripts/deploy.sh
```

3. Store credentials with mysql_config_editor (the script defaults to login-path `local` / user `admin`):
```bash
mysql_config_editor set --login-path=local \
    --host=localhost \
    --user=admin \
    --password
```

4. Deploy schema, migrations, and maintenance seeds:
```bash
./scripts/deploy.sh --login-path=local --with-seeds
```

The deployment script installs the schema (tables, views, procedures, functions, triggers, indexes), applies every versioned migration under `migrations/`, and conditionally loads `seeds/dev/`. It prints the login path (or reports that it will prompt for a password) so you always know which credentials are in use.

## Database Features

### Core Entities

- **Accounts** - Chart of accounts (hierarchical)
- **Transactions** - Journal entries (double-entry bookkeeping)
- **Transaction Lines** - Debit/credit line items
- **Fiscal Periods** - Financial reporting periods
- **Budgets** - Budget planning and tracking
- **Currencies** - Multi-currency support with exchange rates

### Key Features

- Double-entry bookkeeping enforcement
- Multi-currency transaction support
- Hierarchical chart of accounts
- Fiscal period management
- Budget vs. actual tracking
- Complete audit trail (timestamps, user tracking)
- Referential integrity via foreign keys

## Contributing

### Making Schema Changes

1. Create a new migration file with the next version number
2. Write idempotent SQL when possible
3. Test migration locally
4. Run validation: `./scripts/validate.sh`
5. Commit and create pull request
6. Ensure CI checks pass

### Best Practices

- ✅ Use `IF NOT EXISTS` / `IF EXISTS` for idempotency
- ✅ Include rollback instructions in migration comments
- ✅ Test migrations on a copy of production data
- ✅ Keep migrations small and focused
- ✅ Document complex changes
- ❌ Never modify existing migrations
- ❌ Never commit sensitive data or credentials
- ❌ Avoid breaking changes without coordination

## Documentation

Detailed documentation available in `/docs`:

- **[migration-strategy.md](docs/migration-strategy.md)** - Migration guidelines and best practices
- **[schema.md](docs/schema.md)** - Complete schema documentation with all tables and relationships

Each directory also has its own README:
- [migrations/README.md](migrations/README.md) - Migration guidelines and best practices
- [seeds/README.md](seeds/README.md) - Seed data usage and customization
- [scripts/README.md](scripts/README.md) - Script usage and CI integration

## Support

For questions or issues:
- Create an issue in this repository
- Contact the Finance API team
- See `docs/` for additional documentation

## Related Projects

- **lumanitech-erp-api-finance** - Finance API service (owner of this database)

## License

Internal use only - Lumanitech ERP System
