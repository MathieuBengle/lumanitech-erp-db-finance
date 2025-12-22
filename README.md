# Lumanitech ERP - Finance Database

MySQL database repository for the Finance module of Lumanitech ERP system.

## Overview

This repository contains **database schema, migrations, and seed data only** - no application code. The database is owned and accessed exclusively by the Finance API service.

## Repository Structure

```
lumanitech-erp-db-finance/
├── schema/                 # Base database schema (initial structure)
│   ├── 01_create_database.sql
│   ├── 02_accounts.sql
│   ├── 03_transactions.sql
│   ├── 04_transaction_lines.sql
│   ├── 05_fiscal_periods.sql
│   └── README.md
├── migrations/             # Versioned migration scripts (forward-only)
│   ├── V001__create_migration_tracking_table.sql
│   ├── V002__add_budget_tables.sql
│   ├── V003__add_currency_support.sql
│   └── README.md
├── seeds/                  # Sample/reference data (dev/test only)
│   ├── 01_currencies.sql
│   ├── 02_chart_of_accounts.sql
│   ├── 03_fiscal_periods.sql
│   └── README.md
├── scripts/                # Management and CI/CD scripts
│   ├── deploy.sh           # Single deployment script
│   ├── validate.sh         # Validate SQL (CI-ready)
│   └── README.md
├── docs/                   # Documentation
│   ├── ARCHITECTURE.md     # Database architecture and ownership
│   └── SCHEMA.md           # Detailed schema documentation
├── .gitignore              # Git ignore rules
└── README.md               # This file
```

## Quick Start

### Prerequisites

- MySQL 8.0 or higher
- MySQL client (`mysql` command)
- Bash shell

### Setup Development Database

```bash
# 1. Clone the repository
git clone https://github.com/MathieuBengle/lumanitech-erp-db-finance.git
cd lumanitech-erp-db-finance

# 2. Set up MySQL login path with credentials
mysql_config_editor set --login-path=local \
  --host=localhost \
  --user=root \
  --password

# 3. Deploy schema and migrations
./scripts/deploy.sh

# 4. (Optional) Load seed data for development
./scripts/deploy.sh --with-seeds
```

### Validate SQL Files

```bash
./scripts/validate.sh
```

## Database Ownership

### Owner: Finance API Service

The Finance database is **owned by the Finance API**. This means:

- ✅ All database access goes through the Finance API
- ✅ API contains all business logic and validation
- ✅ Database enforces referential integrity only
- ❌ No direct database access by other services
- ❌ No application code in this repository

### Access Control

| Access Type | Allowed For | Purpose |
|-------------|-------------|---------|
| Read/Write via API | Finance API Service | Normal operations |
| Direct SQL (read-only) | BI/Reporting tools | Analytics, reports |
| Direct SQL (admin) | DBAs | Maintenance, backups |
| Migration scripts | CI/CD pipeline | Schema updates |

## Migration Strategy

This project follows a **strict forward-only migration strategy**:

### Principles

1. **Versioned migrations** - Each migration has a unique version number
2. **Immutable migrations** - Once applied, NEVER modify a migration
3. **Forward-only** - No rollback scripts
4. **Tracked history** - All migrations tracked in `schema_migrations` table
5. **To fix errors** - Create a new migration, don't edit existing ones

### Migration Naming

```
V{version}__{description}.sql
```

Examples:
- `V001__create_migration_tracking_table.sql`
- `V002__add_budget_tables.sql`
- `V003__add_currency_support.sql`

### Creating Migrations

1. Determine next version number
2. Create file following naming convention
3. Write SQL with proper header comments
4. Test in development environment
5. Run validation: `./scripts/validate.sh`
6. Commit to repository
7. Apply via CI/CD pipeline

**See** [migrations/README.md](migrations/README.md) for detailed guidelines.

## Core Database Features

### Entities

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

## CI/CD Integration

### Validation in CI

Add to your CI pipeline:

```yaml
# GitHub Actions example
- name: Validate SQL
  run: ./scripts/validate.sh
```

**Exit codes**:
- `0` - All validations passed
- `1` - Validation errors found

### Deployment

Recommended deployment process:

1. **Development**: Test migrations locally
2. **CI**: Validate SQL syntax and conventions
3. **Staging**: Apply migrations to staging database
4. **Validation**: Test with staging API
5. **Production**: Apply migrations during maintenance window

```bash
# Production deployment example (using mysql_config_editor)
mysql_config_editor set --login-path=finance_prod --host=db-prod.example.com --user=finance_app
./scripts/deploy.sh --login-path=finance_prod
```

## Documentation

Detailed documentation available in `/docs`:

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Database architecture, ownership model, design principles
- **[SCHEMA.md](docs/SCHEMA.md)** - Complete schema documentation with all tables and relationships

Each directory also has its own README:
- [schema/README.md](schema/README.md) - Schema files documentation
- [migrations/README.md](migrations/README.md) - Migration guidelines and best practices
- [seeds/README.md](seeds/README.md) - Seed data usage and customization
- [scripts/README.md](scripts/README.md) - Script usage and CI integration

## Development Guidelines

### Making Changes

1. **Never modify existing migrations** - Create new ones
2. **Test locally first** - Use development database
3. **Validate before committing** - Run `./scripts/validate.sh`
4. **Document changes** - Update docs if schema changes significantly
5. **Keep migrations focused** - One logical change per migration

### Code Style

- Use consistent formatting (2 or 4 space indentation)
- Add comments for complex logic
- Follow existing naming conventions
- Use UPPERCASE for SQL keywords
- Include descriptive header comments

### Testing

- Test migrations in isolation
- Verify foreign key constraints
- Check index performance
- Test with seed data
- Validate business rules

## Security

- ⚠️ **Never commit credentials** to repository
- Use environment variables for passwords
- Database credentials managed separately
- SSL/TLS for database connections in production
- Principle of least privilege for database users

## Support and Contribution

### Reporting Issues

- Database bugs: Create issue with error logs
- Schema questions: Check documentation first
- Migration problems: Include migration version and error

### Contributing

1. Fork the repository
2. Create feature branch
3. Add your migration(s)
4. Validate with `./scripts/validate.sh`
5. Submit pull request
6. Ensure CI checks pass

## License

[Specify your license here]

## Authors

- Lumanitech ERP Team

## Related Projects

- **lumanitech-erp-finance-api** - Finance API service (owner of this database)
- **lumanitech-erp-db-*** - Other module databases

---

**Remember**: This is a database repository only. No application code belongs here.
