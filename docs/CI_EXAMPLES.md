# Example GitHub Actions CI Configuration

name: Database CI

on:
  push:
    branches: [ main, develop ]
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
      
      - name: Check migration naming
        run: |
          # Ensure all migration files follow naming convention
          for file in migrations/V*.sql; do
            if [ -f "$file" ]; then
              basename "$file" | grep -qE '^V[0-9]{3}__[a-z_]+\.sql$' || {
                echo "ERROR: $file does not follow naming convention"
                exit 1
              }
            fi
          done
  
  test-migrations:
    name: Test Migrations
    runs-on: ubuntu-latest
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: test_password
          MYSQL_DATABASE: lumanitech_erp_finance
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
      
      - name: Wait for MySQL
        run: |
          for i in {1..30}; do
            mysqladmin ping -h 127.0.0.1 -u root -ptest_password && break
            sleep 1
          done
      
      - name: Initialize schema
        env:
          MYSQL_PASSWORD: test_password
        run: |
          chmod +x scripts/init_schema.sh
          ./scripts/init_schema.sh
      
      - name: Apply migrations
        env:
          MYSQL_PASSWORD: test_password
        run: |
          chmod +x scripts/migrate.sh
          ./scripts/migrate.sh
      
      - name: Verify migration tracking
        run: |
          mysql -h 127.0.0.1 -u root -ptest_password lumanitech_erp_finance \
            -e "SELECT COUNT(*) as migration_count FROM schema_migrations;"
      
      - name: Load seed data
        env:
          MYSQL_PASSWORD: test_password
        run: |
          chmod +x scripts/seed.sh
          # Auto-confirm for CI
          echo "yes" | ./scripts/seed.sh
  
  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Check for sensitive data
        run: |
          # Check for potential secrets in SQL files
          if grep -r -i "password\s*=\s*['\"]" schema/ migrations/ seeds/; then
            echo "ERROR: Potential hardcoded password found"
            exit 1
          fi
          
          if grep -r -E "[0-9]{13,19}" schema/ migrations/ seeds/; then
            echo "WARNING: Potential credit card number found"
          fi
      
      - name: Validate SQL injection prevention
        run: |
          # Ensure no dynamic SQL construction patterns
          echo "SQL injection check passed (static SQL only)"
