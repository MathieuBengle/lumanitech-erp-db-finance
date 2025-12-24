-- ============================================================================
-- Migration: V002_add_budget_tables
-- Description: Add tables for budget management
-- Date: 2025-12-21
-- Author: System
-- ============================================================================

USE lumanitech_erp_finance;

-- Create budgets table
CREATE TABLE IF NOT EXISTS budgets (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  budget_code VARCHAR(50) NOT NULL,
  budget_name VARCHAR(255) NOT NULL,
  fiscal_period_id BIGINT UNSIGNED NOT NULL,
  status ENUM('DRAFT', 'ACTIVE', 'CLOSED') NOT NULL DEFAULT 'DRAFT',
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (id),
  UNIQUE KEY uk_budget_code (budget_code),
  KEY idx_fiscal_period (fiscal_period_id),
  KEY idx_status (status),
  
  CONSTRAINT fk_budgets_fiscal_period
    FOREIGN KEY (fiscal_period_id)
    REFERENCES fiscal_periods(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create budget_lines table
CREATE TABLE IF NOT EXISTS budget_lines (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  budget_id BIGINT UNSIGNED NOT NULL,
  account_id BIGINT UNSIGNED NOT NULL,
  budgeted_amount DECIMAL(15, 2) NOT NULL,
  description VARCHAR(500),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (id),
  KEY idx_budget_id (budget_id),
  KEY idx_account_id (account_id),
  UNIQUE KEY uk_budget_account (budget_id, account_id),
  
  CONSTRAINT fk_budget_lines_budget
    FOREIGN KEY (budget_id)
    REFERENCES budgets(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  
  CONSTRAINT fk_budget_lines_account
    FOREIGN KEY (account_id)
    REFERENCES accounts(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Self-tracking: Record this migration
-- ============================================================================

INSERT INTO schema_migrations (version, description)
VALUES ('V002', 'add_budget_tables')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
