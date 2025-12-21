# Scripts Directory

This directory contains utility scripts for database management and CI/CD integration.

## Available Scripts

### init_schema.sh
**Purpose**: Initialize the database schema from scratch

**Usage**:
```bash
./scripts/init_schema.sh
```

**What it does**:
- Creates the database
- Executes all schema files in order
- Sets up initial table structure

**When to use**:
- Setting up a new development environment
- Creating a fresh test database
- Initial deployment to a new environment

**Prerequisites**:
- MySQL client installed
- Database credentials (MYSQL_USER, MYSQL_PASSWORD)

---

### migrate.sh
**Purpose**: Apply database migrations with version tracking

**Usage**:
```bash
./scripts/migrate.sh
```

**What it does**:
- Checks which migrations have been applied
- Applies pending migrations in order
- Records migration history in `schema_migrations` table
- Tracks execution time and success status

**Features**:
- Idempotent - safe to run multiple times
- Skips already-applied migrations
- Forward-only migration strategy
- Detailed logging

**When to use**:
- After pulling new migrations from repository
- During deployment process
- Upgrading database to latest version

---

### seed.sh
**Purpose**: Load sample/reference data into database

**Usage**:
```bash
./scripts/seed.sh
```

**What it does**:
- Loads seed data files in order
- Prompts for confirmation (safety measure)
- Uses upsert patterns (idempotent)

**When to use**:
- Development environment setup
- Testing data population
- Demo environment preparation
- Loading reference data (currencies, etc.)

**Warning**: NOT for production use (except specific reference data)

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
- UTF-8 encoding
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

## Environment Variables

All scripts support these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| MYSQL_USER | MySQL username | root |
| MYSQL_PASSWORD | MySQL password | (prompted) |
| DB_NAME | Database name | lumanitech_erp_finance |

**Example**:
```bash
export MYSQL_USER=dbadmin
export MYSQL_PASSWORD=secretpassword
./scripts/migrate.sh
```

## Script Execution Order

For a fresh setup:

1. **init_schema.sh** - Create database and base schema
2. **migrate.sh** - Apply all migrations
3. **seed.sh** - Load seed data (optional, dev only)

For updates:

1. **validate.sh** - Validate new SQL files
2. **migrate.sh** - Apply new migrations

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

All scripts:
- Exit on first error (`set -e`)
- Provide colored output for visibility
- Return appropriate exit codes
- Log operations for troubleshooting

## Security Notes

- Never commit database passwords to repository
- Use environment variables or secret management
- Scripts prompt for password if not in environment
- Seed script requires confirmation before execution

## Logging

Scripts provide detailed output including:
- ✓ Success indicators (green)
- ✗ Error indicators (red)
- ⚠ Warnings (yellow)
- Execution times
- File names being processed

## Troubleshooting

### "MySQL client not found"
Install MySQL client: `apt-get install mysql-client` (Ubuntu/Debian)

### "Permission denied"
Make scripts executable: `chmod +x scripts/*.sh`

### "Database does not exist"
Run `init_schema.sh` first

### "Migration already applied"
This is normal - migrate.sh skips already-applied migrations

## Development Workflow

1. Create new migration: `migrations/V004__your_change.sql`
2. Test locally: `./scripts/migrate.sh`
3. Validate: `./scripts/validate.sh`
4. Commit and push
5. CI validates automatically
6. Deploy to staging/production

## Maintenance

Scripts are designed to be:
- Self-contained
- Minimal dependencies
- Easy to understand and modify
- Compatible with standard bash environments
