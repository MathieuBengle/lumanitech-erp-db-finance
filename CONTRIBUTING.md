# Contributing to Lumanitech ERP Finance Database

Thank you for your interest in contributing to the Finance database repository!

## Code of Conduct

- Be respectful and professional
- Focus on constructive feedback
- Collaborate openly
- Follow project conventions

## How to Contribute

### Reporting Issues

When reporting a bug or issue:

1. **Search existing issues** first
2. **Provide details**:
   - Database version (MySQL version)
   - Migration version where issue occurs
   - Error messages and logs
   - Steps to reproduce
3. **Use issue templates** if available

### Suggesting Enhancements

For new features or changes:

1. **Open a discussion** or issue first
2. **Explain the use case** and benefit
3. **Consider backward compatibility**
4. **Propose the schema changes**
5. **Wait for feedback** before implementing

## Development Workflow

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR_USERNAME/lumanitech-erp-db-finance.git
cd lumanitech-erp-db-finance
git remote add upstream https://github.com/MathieuBengle/lumanitech-erp-db-finance.git
```

### 2. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

### 3. Make Changes

#### Creating Migrations

1. Determine the next version number:
   ```bash
   ls migrations/ | grep "^V" | sort -V | tail -1
   ```

2. Create migration file:
   ```bash
   # Follow naming convention: V###__description.sql
   vim migrations/V004__add_payment_methods.sql
   ```

3. Add proper header:
   ```sql
   -- ============================================================================
   -- Migration: V004__add_payment_methods
   -- Description: Add payment methods table for transaction processing
   -- Date: 2025-12-21
   -- Author: Your Name
   -- ============================================================================
   
   USE lumanitech_erp_finance;
   
   -- Your SQL statements here
   ```

4. Write idempotent SQL when possible:
   ```sql
   CREATE TABLE IF NOT EXISTS table_name (...);
   ALTER TABLE table_name ADD COLUMN IF NOT EXISTS column_name ...;
   ```

#### Modifying Schema (New Projects Only)

For completely new deployments:
- Schema files can be modified BEFORE first deployment
- After deployment, changes go through migrations only

#### Updating Seeds

- Seeds are for development/testing only
- Use `ON DUPLICATE KEY UPDATE` for idempotency
- Keep seed data realistic but not real
- No sensitive or personal data

### 4. Test Your Changes

```bash
# Setup test database
export MYSQL_PASSWORD=test_password
./scripts/init_schema.sh

# Apply your migration
./scripts/migrate.sh

# Test with seed data
./scripts/seed.sh

# Verify the changes
mysql -u root -p lumanitech_erp_finance -e "DESCRIBE new_table;"

# Check migration tracking
mysql -u root -p lumanitech_erp_finance -e \
  "SELECT * FROM schema_migrations ORDER BY id;"
```

### 5. Validate

```bash
# Run validation script
./scripts/validate.sh

# Should output: "All SQL files passed validation! ✓"
```

### 6. Document Changes

Update documentation if needed:

- **docs/SCHEMA.md** - For new tables or significant schema changes
- **docs/ARCHITECTURE.md** - For architectural changes
- **migrations/README.md** - For migration process changes
- **README.md** - For major feature additions

### 7. Commit Changes

```bash
# Stage your changes
git add migrations/V004__add_payment_methods.sql
git add docs/SCHEMA.md  # if updated

# Commit with descriptive message
git commit -m "Add payment methods table

- Create payment_methods table
- Add foreign key to transactions
- Include common payment types
- Update schema documentation"

# Push to your fork
git push origin feature/your-feature-name
```

### 8. Create Pull Request

1. Go to GitHub and create a Pull Request
2. Fill in the PR template:
   - **Description**: What does this change?
   - **Motivation**: Why is this needed?
   - **Testing**: How was it tested?
   - **Documentation**: What docs were updated?
3. Wait for CI checks to pass
4. Address review feedback

## Coding Standards

### SQL Style Guide

#### Formatting
```sql
-- Use UPPERCASE for SQL keywords
CREATE TABLE accounts (
  -- Use lowercase_with_underscores for identifiers
  account_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_name VARCHAR(255) NOT NULL,
  
  -- Align column definitions
  PRIMARY KEY (account_id),
  KEY idx_account_name (account_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### Indentation
- Use 2 spaces (not tabs)
- Indent nested blocks
- Align related statements

#### Comments
```sql
-- Use single-line comments for brief explanations
/*
 * Use multi-line comments for:
 * - Complex logic explanation
 * - Business rules
 * - Important notes
 */
```

### Naming Conventions

#### Tables
- Use lowercase with underscores: `fiscal_periods`
- Use plural nouns: `accounts`, `transactions`
- Be descriptive: `transaction_lines` not `trans_ln`

#### Columns
- Use lowercase with underscores: `created_at`
- Be descriptive: `transaction_date` not `trans_dt`
- Suffix IDs with `_id`: `account_id`, `transaction_id`
- Use consistent naming across tables

#### Indexes
- Primary keys: Use `PRIMARY KEY`
- Unique: Prefix with `uk_`: `uk_account_code`
- Non-unique: Prefix with `idx_`: `idx_transaction_date`

#### Foreign Keys
- Prefix with `fk_`: `fk_transaction_lines_account`
- Format: `fk_{table}_{referenced_table}`

#### Constraints
- Check constraints: Prefix with `chk_`: `chk_amount_positive`

### Migration Standards

1. **One logical change per migration**
   - Don't mix unrelated changes
   - Keep migrations focused

2. **Include rollback notes**
   ```sql
   -- Rollback: To manually rollback, execute:
   -- DROP TABLE payment_methods;
   -- ALTER TABLE transactions DROP COLUMN payment_method_id;
   ```

3. **Consider performance**
   - Large migrations on big tables need planning
   - Consider adding indexes AFTER data loads
   - Test migration time

4. **Handle existing data**
   - Use ALTER TABLE carefully
   - Provide default values for new NOT NULL columns
   - Consider data migrations for transformations

## Review Process

### What Reviewers Look For

- ✅ Follows naming conventions
- ✅ Proper indexing strategy
- ✅ Foreign key constraints
- ✅ Check constraints for data integrity
- ✅ Backward compatibility
- ✅ Performance implications
- ✅ Documentation updates
- ✅ Tests passed locally
- ✅ Validation script passes

### Addressing Feedback

- Respond to all comments
- Make requested changes or explain why not
- Push updates to the same branch
- Request re-review when ready

## CI/CD Pipeline

Our CI automatically:

1. ✅ Validates SQL syntax
2. ✅ Checks naming conventions
3. ✅ Tests migrations on MySQL
4. ✅ Verifies documentation
5. ✅ Scans for secrets

All checks must pass before merge.

## Getting Help

- **Questions**: Open a discussion or issue
- **Bugs**: Create an issue with details
- **Chat**: [Specify your chat channel]
- **Email**: [Specify contact email]

## Recognition

Contributors will be:
- Listed in commit history
- Mentioned in release notes (for significant contributions)
- Credited in documentation (for major features)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to make this project better! 🎉
