# Database Schema Documentation

## Database Information

- **Database Name**: `lumanitech_erp_finance`
- **Character Set**: `utf8mb4`
- **Collation**: `utf8mb4_unicode_ci`
- **Engine**: InnoDB

## Schema Organization

The schema is organized into subdirectories:

```
schema/
├── 01_create_database.sql  # Database creation
├── tables/                 # Table definitions
├── views/                  # View definitions
├── procedures/             # Stored procedures
├── functions/              # User-defined functions
├── triggers/               # Database triggers
└── indexes/                # Standalone index definitions
```

Naming conventions:
- procedures: sp_<name>.sql
- triggers: trg_<name>.sql

## Core Tables

### schema_migrations

Tracks all applied database migrations.

| Column | Type | Description |
|--------|------|-------------|
| version | VARCHAR(50) | Migration version (V001, V002, etc.) |
| description | VARCHAR(255) | Brief description of the migration |
| applied_at | TIMESTAMP | When the migration was applied |

**Indexes:**
- PRIMARY KEY on `version`
- INDEX on `applied_at`

### Finance Module Tables

#### accounts

Chart of accounts for the finance system.

Key features:
- Hierarchical account structure
- Account types: ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE
- Active/inactive status

#### transactions

Financial journal entries following double-entry bookkeeping.

Key features:
- Unique transaction numbers
- Multi-currency support
- Status tracking (DRAFT, POSTED, VOIDED)
- Audit trail (timestamps, user tracking)

#### transaction_lines

Individual debit/credit line items for transactions.

Key features:
- Links to transactions and accounts
- Line type (DEBIT or CREDIT)
- Non-negative amounts
- Cascading deletes with parent transaction

#### fiscal_periods

Fiscal periods for financial reporting.

Key features:
- Period codes
- Start and end dates
- Status (OPEN, CLOSED)
- Year and quarter tracking

#### budgets

Budget planning and tracking.

Key features:
- Budget codes
- Links to fiscal periods
- Status (DRAFT, ACTIVE, CLOSED)

#### budget_lines

Individual budget line items.

Key features:
- Links to budgets and accounts
- Budgeted amounts

#### currencies

Multi-currency support.

Key features:
- Currency codes (ISO 4217)
- Currency names and symbols
- Decimal places
- Active/inactive status

#### exchange_rates

Currency exchange rates.

Key features:
- From/to currency relationships
- Exchange rates
- Effective dates
- Positive rate constraint

## Relationships

```
currencies ← transactions → transaction_lines → accounts
                 ↓
           fiscal_periods ← budgets → budget_lines → accounts
```

## See Also

- [Migration Strategy](migration-strategy.md) - How to create and apply migrations
- [Data Dictionary](DATA_DICTIONARY.md) - Complete field-level documentation
- [Database Design](DATABASE_DESIGN.md) - Architecture and design principles
