# Scripts Directory

This directory contains the CI/CD helpers for the Finance database repository.

## Available Scripts

### deploy.sh
**Purpose**: Deploy the schema, migrations, and optional development seeds while reusing `mysql_config_editor` login paths (default login-path `local` + user `admin`).

**Usage**:
```bash
# Ensure the script is executable (run once)
chmod +x ./scripts/deploy.sh

# Basic deployment (schema + migrations)
./scripts/deploy.sh

# Include seed data for local development
./scripts/deploy.sh --with-seeds

# Override login path or database name
./scripts/deploy.sh --login-path=local --database=lumanitech_erp_finance
```

**Notes**:
- The script auto-verifies the configured login path and prints instructions if it is missing.
- If no login path is provided or found, it falls back to an interactive password prompt that is reused for the entire run.
- Schema directories (`schema/tables`, `schema/views`, `schema/procedures`, `schema/functions`, `schema/triggers`, `schema/indexes`), the `migrations/` folder, and `seeds/dev/` are executed in alphabetical order.

### validate.sh
**Purpose**: Validate SQL files for syntax and naming conventions (CI-ready).

**Usage**:
```bash
./scripts/validate.sh
```
