-- ============================================================================
-- Table: fiscal_periods
-- Description: Define fiscal periods for financial reporting
-- ============================================================================

CREATE TABLE IF NOT EXISTS fiscal_periods (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  period_code VARCHAR(20) NOT NULL,
  period_name VARCHAR(100) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  fiscal_year INT NOT NULL,
  is_closed BOOLEAN NOT NULL DEFAULT FALSE,
  closed_at TIMESTAMP NULL DEFAULT NULL,
  closed_by VARCHAR(100),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (id),
  UNIQUE KEY uk_period_code (period_code),
  KEY idx_fiscal_year (fiscal_year),
  KEY idx_is_closed (is_closed),
  KEY idx_dates (start_date, end_date),
  
  CONSTRAINT chk_date_range
    CHECK (end_date >= start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
