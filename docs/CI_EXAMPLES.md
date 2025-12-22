# Example CI/CD Configuration

This document provides examples of how to integrate the database deployment scripts into various CI/CD pipelines.

## GitHub Actions

### Validation Only (Recommended for PR checks)

```yaml
name: Database Validation

on:
  pull_request:
    branches: [ main, develop ]

jobs:
  validate-sql:
    name: Validate SQL Files
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Validate SQL syntax and conventions
        run: |
          chmod +x scripts/validate.sh
          ./scripts/validate.sh
```

### Full Deployment Test

```yaml
name: Database Deployment Test

on:
  push:
    branches: [ main, develop ]

jobs:
  test-deployment:
    name: Test Database Deployment
    runs-on: ubuntu-latest
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: test_password
        ports:
          - 3306:3306
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up MySQL login path
        run: |
          mysql_config_editor set --login-path=ci \
            --host=127.0.0.1 \
            --user=root \
            --password=test_password
      
      - name: Deploy database
        run: |
          chmod +x scripts/deploy.sh
          ./scripts/deploy.sh --login-path=ci --with-seeds
```

## Best Practices

1. **Validation on Every PR**: Run `validate.sh` on pull requests
2. **Separate Environments**: Use different login paths for dev/staging/prod
3. **Secure Credentials**: Use mysql_config_editor, never commit passwords
4. **Test Migrations**: Test deployment in CI before merging
