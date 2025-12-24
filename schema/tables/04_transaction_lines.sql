-- ============================================================================
-- Table: transaction_lines
-- Description: Individual debit/credit lines for each transaction
-- ============================================================================

CREATE TABLE IF NOT EXISTS transaction_lines (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  transaction_id BIGINT UNSIGNED NOT NULL,
  account_id BIGINT UNSIGNED NOT NULL,
  line_type ENUM('DEBIT', 'CREDIT') NOT NULL,
  amount DECIMAL(15, 2) NOT NULL,
  description VARCHAR(500),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (id),
  KEY idx_transaction_id (transaction_id),
  KEY idx_account_id (account_id),
  KEY idx_line_type (line_type),
  
  CONSTRAINT fk_transaction_lines_transaction
    FOREIGN KEY (transaction_id)
    REFERENCES transactions(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  
  CONSTRAINT fk_transaction_lines_account
    FOREIGN KEY (account_id)
    REFERENCES accounts(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  
  CONSTRAINT chk_amount_positive
    CHECK (amount >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
