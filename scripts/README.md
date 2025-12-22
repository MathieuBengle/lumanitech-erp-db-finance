# Scripts Directory

This directory contains utility scripts for database management and CI/CD integration.

## Available Scripts

### setup.sh
**Purpose**: Single deployment script for schema, migrations, and optionally seed data

**Usage**:
```bash
# Basic deployment (schema + migrations)
./scripts/setup.sh

# Deployment with seed data (dev/test only)
./scripts/setup.sh --with-seeds

# Override database name or login path
./scripts/deploy.sh --database=lumanitech_projects --login-path=local

# Override host/user or rely on interactive password
./scripts/deploy.sh --host=127.0.0.1 --user=finance_admin

# Show help
./scripts/setup.sh --help
```

**What it does**:
- Creates database if it doesn't exist
- Initializes schema (tables, constraints, indexes)
- Applies pending migrations in order
- Optionally loads seed data
- Records migration history in `schema_migrations` table
- Tracks execution time and success status

- Single script for all deployment tasks
- Uses mysql_config_editor for secure credential management but fallbacks to an interactive prompt when no login path exists
- Auto-detects the first available login path if none is provided and honors the MYSQL_LOGIN_PATH env var
- Idempotent - safe to run multiple times
- Skips already-applied migrations
- Forward-only migration strategy
- Detailed colored logging
- Command-line options for flexibility

**When to use**:
- Initial setup of new environment
- Deploying updates to existing database
- Development environment refresh
- CI/CD deployment pipelines

**Prerequisites**:
- MySQL client with mysql_config_editor installed (required only if you rely on login paths)
- Optional: configured login path for non-interactive runs (script falls back to interactive password entry)

---

### validate.sh
**Purpose**: Validate SQL files for syntax and convention compliance (CI-ready)

**Usage**:
```bash
./scripts/validate.sh
```

**Exit codes**:
- 0: All validations passed
- 1: Validation errors found

**Checks performed**:
- Files are not empty
- Files contain valid SQL keywords
- Balanced parentheses
- Migration naming conventions
- UTF-8/ASCII encoding
- File endings (newlines)
- No tabs (warning only)

**When to use**:
- Pre-commit hooks
- CI/CD pipelines
- Before submitting pull requests
- Local development validation

**CI Integration**:
```yaml
# Example GitHub Actions
- name: Validate SQL
  run: ./scripts/validate.sh
```

---

## MySQL Login Path

This repository uses **mysql_config_editor** for secure credential management instead of environment variables or command-line passwords.

### Setting up a Login Path

Create a login path for your environment:

```bash
# For local development
mysql_config_editor set --login-path=local \
  --host=localhost \
  --user=root \
  --password

# For production
mysql_config_editor set --login-path=production \
  --host=prod-db-server \
  --user=db_admin \
  --password
```

You will be prompted to enter the password securely.

### Managing Login Paths

```bash
# List all configured login paths
mysql_config_editor print --all

# Remove a login path
mysql_config_editor remove --login-path=local

# Test a login path
mysql --login-path=local -e "SELECT 1;"
```

### Benefits

- ✅ **Security**: Passwords stored encrypted in ~/.mylogin.cnf
- ✅ **No exposure**: Passwords never appear in process lists
- ✅ **No environment variables**: No need to export passwords
- ✅ **Audit trail**: Clear which login path is used

---

## Script Execution

```bash
# Ensure the deployment script is executable
chmod +x ./scripts/deploy.sh
```

### For a fresh setup:

```bash
# 1. Set up login path (optional, not required for the script to run)
mysql_config_editor set --login-path=local \
  --host=localhost \
  --user=root \
  --password

# 2. Deploy everything
export MYSQL_LOGIN_PATH=local  # optional: avoids typing --login-path every time
./scripts/deploy.sh

# 3. (Optional) Add seed data for development
./scripts/setup.sh --with-seeds
```

If you skip the login path, the script prompts once for the password and reuses it for the whole run so credentials never appear on the command line.

### For updates:

```bash
# Deploy new migrations
./scripts/setup.sh

# Or specify login path
./scripts/setup.sh --login-path=production
```

### For CI/CD:

```bash
# Validate SQL files
./scripts/validate.sh
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Database CI

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Validate SQL files
        run: ./scripts/validate.sh
```

### GitLab CI Example

```yaml
validate-sql:
  stage: test
  script:
    - ./scripts/validate.sh
  only:
    - merge_requests
    - main
```

## Error Handling

Most scripts:
- Exit on first error (`set -e`) to fail fast on unexpected problems
- Provide colored output for visibility
- Return appropriate exit codes
- Log operations for troubleshooting

Note: `validate.sh` intentionally does **not** use `set -e` so it can process all files and report all validation errors in a single run.
## Security Notes

- Passwords stored encrypted using mysql_config_editor
- No passwords in process lists or environment variables
- Login paths stored in ~/.mylogin.cnf (encrypted)
- Never commit credentials to repository
- Seed script warns before execution

## Logging

Scripts provide detailed output including:
- ✓ Success indicators (green)
- ✗ Error indicators (red)
- ⚠ Warnings (yellow)
- 📘 Migration indicators (blue)
- Execution times
- File names being processed

## Troubleshooting

### "MySQL client not found"
Install MySQL client: `apt-get install mysql-client` (Ubuntu/Debian)

### "mysql_config_editor not found"
mysql_config_editor is included with MySQL client. Ensure MySQL client 5.6+ is installed.

### "Login path not found"
Create the login path first:
```bash
mysql_config_editor set --login-path=local --host=localhost --user=root --password
```

### "Permission denied"
Make scripts executable: `chmod +x scripts/*.sh`

### "Database already exists"
The deploy script will skip schema initialization and only apply migrations.

### "Migration already applied"
This is normal - setup.sh skips already-applied migrations

## Development Workflow

1. Create new migration: `migrations/V004__your_change.sql`
2. Test locally: `./scripts/setup.sh`
3. Validate: `./scripts/validate.sh`
4. Commit and push
5. CI validates automatically
6. Deploy to staging/production with `./scripts/setup.sh --login-path=production`

## Maintenance

Scripts are designed to be:
- Self-contained
- Minimal dependencies (just MySQL client)
- Easy to understand and modify
- Compatible with standard bash environments
- Secure by default (mysql_config_editor)
