-- ============================================================================
-- Table: accounts
-- Description: Chart of accounts - defines all financial accounts
-- ============================================================================

CREATE TABLE IF NOT EXISTS accounts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_code VARCHAR(50) NOT NULL,
  account_name VARCHAR(255) NOT NULL,
  account_type ENUM('ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE') NOT NULL,
  parent_account_id BIGINT UNSIGNED DEFAULT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (id),
  UNIQUE KEY uk_account_code (account_code),
  KEY idx_account_type (account_type),
  KEY idx_parent_account (parent_account_id),
  KEY idx_is_active (is_active),
  
  CONSTRAINT fk_accounts_parent
    FOREIGN KEY (parent_account_id)
    REFERENCES accounts(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
