# Database Schema Documentation

## Database: lumanitech_erp_finance

Character Set: `utf8mb4`  
Collation: `utf8mb4_unicode_ci`  
Engine: `InnoDB`

## Table Reference

### Core Tables

#### accounts
**Purpose**: Chart of Accounts - defines all financial accounts in the system

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Unique account identifier |
| account_code | VARCHAR(50) | NOT NULL, UNIQUE | Unique account code (e.g., "1100") |
| account_name | VARCHAR(255) | NOT NULL | Descriptive account name |
| account_type | ENUM | NOT NULL | ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE |
| parent_account_id | BIGINT UNSIGNED | FK → accounts.id | Parent account for hierarchy |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE | Whether account is active |
| description | TEXT | | Detailed account description |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | NOT NULL, ON UPDATE | Last update time |

**Indexes**:
- `uk_account_code` (account_code) - UNIQUE
- `idx_account_type` (account_type)
- `idx_parent_account` (parent_account_id)
- `idx_is_active` (is_active)

**Constraints**:
- Self-referencing FK to support hierarchical structure
- RESTRICT on delete to prevent orphaned child accounts

---

#### transactions
**Purpose**: Financial transactions (journal entries)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Unique transaction identifier |
| transaction_number | VARCHAR(50) | NOT NULL, UNIQUE | Human-readable transaction number |
| transaction_date | DATE | NOT NULL | Date of transaction |
| description | VARCHAR(500) | NOT NULL | Transaction description |
| currency_id | BIGINT UNSIGNED | FK → currencies.id | Transaction currency |
| reference | VARCHAR(100) | | External reference number |
| status | ENUM | NOT NULL, DEFAULT 'DRAFT' | DRAFT, POSTED, VOIDED |
| created_by | VARCHAR(100) | NOT NULL | User who created transaction |
| posted_at | TIMESTAMP | | When transaction was posted |
| posted_by | VARCHAR(100) | | User who posted transaction |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | NOT NULL, ON UPDATE | Last update time |

**Indexes**:
- `uk_transaction_number` (transaction_number) - UNIQUE
- `idx_transaction_date` (transaction_date)
- `idx_status` (status)
- `idx_currency_id` (currency_id)
- `idx_created_at` (created_at)

**Business Rules**:
- Only DRAFT transactions can be edited
- POSTED transactions are immutable
- VOIDED transactions are marked for reversal

---

#### transaction_lines
**Purpose**: Individual debit/credit lines for transactions

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Unique line identifier |
| transaction_id | BIGINT UNSIGNED | NOT NULL, FK → transactions.id | Parent transaction |
| account_id | BIGINT UNSIGNED | NOT NULL, FK → accounts.id | Account being debited/credited |
| line_type | ENUM | NOT NULL | DEBIT or CREDIT |
| amount | DECIMAL(15,2) | NOT NULL, CHECK >= 0 | Transaction amount |
| description | VARCHAR(500) | | Line-specific description |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | NOT NULL, ON UPDATE | Last update time |

**Indexes**:
- `idx_transaction_id` (transaction_id)
- `idx_account_id` (account_id)
- `idx_line_type` (line_type)

**Constraints**:
- CASCADE delete when transaction is deleted
- Amount must be non-negative
- Total debits must equal total credits (enforced by API)

---

#### fiscal_periods
**Purpose**: Define fiscal periods for financial reporting

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Unique period identifier |
| period_code | VARCHAR(20) | NOT NULL, UNIQUE | Period code (e.g., "2025-01") |
| period_name | VARCHAR(100) | NOT NULL | Display name |
| start_date | DATE | NOT NULL | Period start date |
| end_date | DATE | NOT NULL, CHECK >= start_date | Period end date |
| fiscal_year | INT | NOT NULL | Fiscal year number |
| is_closed | BOOLEAN | NOT NULL, DEFAULT FALSE | Whether period is closed |
| closed_at | TIMESTAMP | | When period was closed |
| closed_by | VARCHAR(100) | | User who closed period |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | NOT NULL, ON UPDATE | Last update time |

**Indexes**:
- `uk_period_code` (period_code) - UNIQUE
- `idx_fiscal_year` (fiscal_year)
- `idx_is_closed` (is_closed)
- `idx_dates` (start_date, end_date)

**Business Rules**:
- No posting to closed periods
- End date must be >= start date
- Once closed, cannot be reopened

---

### Budget Tables (Added in V002)

#### budgets
**Purpose**: Budget definitions

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Unique budget identifier |
| budget_code | VARCHAR(50) | NOT NULL, UNIQUE | Budget code |
| budget_name | VARCHAR(255) | NOT NULL | Budget name |
| fiscal_period_id | BIGINT UNSIGNED | NOT NULL, FK → fiscal_periods.id | Associated fiscal period |
| status | ENUM | NOT NULL, DEFAULT 'DRAFT' | DRAFT, ACTIVE, CLOSED |
| description | TEXT | | Budget description |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | NOT NULL, ON UPDATE | Last update time |

#### budget_lines
**Purpose**: Budget line items

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Unique line identifier |
| budget_id | BIGINT UNSIGNED | NOT NULL, FK → budgets.id | Parent budget |
| account_id | BIGINT UNSIGNED | NOT NULL, FK → accounts.id | Account being budgeted |
| budgeted_amount | DECIMAL(15,2) | NOT NULL | Budgeted amount |
| description | VARCHAR(500) | | Line description |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | NOT NULL, ON UPDATE | Last update time |

**Constraints**:
- Unique constraint on (budget_id, account_id) - one budget line per account per budget

---

### Currency Tables (Added in V003)

#### currencies
**Purpose**: Currency definitions

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Unique currency identifier |
| currency_code | CHAR(3) | NOT NULL, UNIQUE | ISO 4217 currency code |
| currency_name | VARCHAR(100) | NOT NULL | Currency name |
| currency_symbol | VARCHAR(10) | | Currency symbol |
| decimal_places | TINYINT UNSIGNED | NOT NULL, DEFAULT 2 | Number of decimal places |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE | Whether currency is active |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | NOT NULL, ON UPDATE | Last update time |

#### exchange_rates
**Purpose**: Historical exchange rates

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Unique rate identifier |
| from_currency_id | BIGINT UNSIGNED | NOT NULL, FK → currencies.id | Source currency |
| to_currency_id | BIGINT UNSIGNED | NOT NULL, FK → currencies.id | Target currency |
| rate | DECIMAL(20,6) | NOT NULL, CHECK > 0 | Exchange rate |
| effective_date | DATE | NOT NULL | Date rate is effective |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Record creation time |

**Indexes**:
- `idx_currencies` (from_currency_id, to_currency_id, effective_date) - Composite index for lookups

---

### Migration Tracking (Added in V001)

#### schema_migrations
**Purpose**: Track applied database migrations

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Unique migration identifier |
| version | VARCHAR(50) | NOT NULL, UNIQUE | Migration version (e.g., "V001") |
| description | VARCHAR(255) | NOT NULL | Migration description |
| script_name | VARCHAR(255) | NOT NULL | Script filename |
| checksum | VARCHAR(64) | | File checksum for verification |
| installed_by | VARCHAR(100) | NOT NULL | User who applied migration |
| installed_on | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | When migration was applied |
| execution_time | INT UNSIGNED | NOT NULL | Execution time in milliseconds |
| success | BOOLEAN | NOT NULL, DEFAULT TRUE | Whether migration succeeded |

---

## Entity Relationships

```
accounts (1) ←→ (*) accounts (self-referencing hierarchy)
accounts (1) ←→ (*) transaction_lines
accounts (1) ←→ (*) budget_lines

transactions (1) ←→ (*) transaction_lines
transactions (*) ←→ (1) currencies

fiscal_periods (1) ←→ (*) budgets

budgets (1) ←→ (*) budget_lines

currencies (1) ←→ (*) exchange_rates (as from_currency)
currencies (1) ←→ (*) exchange_rates (as to_currency)
```

## Data Types and Precision

- **Money amounts**: DECIMAL(15,2) - supports up to 999,999,999,999.99
- **Exchange rates**: DECIMAL(20,6) - high precision for currency conversion
- **Timestamps**: Standard MySQL TIMESTAMP with timezone support
- **Text**: utf8mb4 for full Unicode support including emoji

## Indexes Strategy

- **Primary Keys**: All tables have auto-increment BIGINT UNSIGNED
- **Foreign Keys**: Indexed automatically
- **Unique Constraints**: On business keys (codes, numbers)
- **Query Optimization**: Composite indexes on frequently queried columns
- **Date Ranges**: Indexes on date columns for period queries

## Constraints

- **Foreign Keys**: RESTRICT on delete (prevent orphaned records), CASCADE on update
- **Check Constraints**: Validate data integrity (amounts > 0, end_date >= start_date)
- **Unique Constraints**: Prevent duplicate business keys
- **NOT NULL**: Required fields enforced at database level
