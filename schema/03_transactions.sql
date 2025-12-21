-- ============================================================================
-- Table: transactions
-- Description: Financial transactions (journal entries)
-- ============================================================================

CREATE TABLE IF NOT EXISTS transactions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  transaction_number VARCHAR(50) NOT NULL,
  transaction_date DATE NOT NULL,
  description VARCHAR(500) NOT NULL,
  reference VARCHAR(100),
  status ENUM('DRAFT', 'POSTED', 'VOIDED') NOT NULL DEFAULT 'DRAFT',
  created_by VARCHAR(100) NOT NULL,
  posted_at TIMESTAMP NULL DEFAULT NULL,
  posted_by VARCHAR(100),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (id),
  UNIQUE KEY uk_transaction_number (transaction_number),
  KEY idx_transaction_date (transaction_date),
  KEY idx_status (status),
  KEY idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
