-- ============================================================================
-- Migration: V003__add_currency_support
-- Description: Add multi-currency support to the system
-- Date: 2025-12-21
-- Author: System
-- ============================================================================

USE lumanitech_erp_finance;

-- Create currencies table
CREATE TABLE IF NOT EXISTS currencies (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  currency_code CHAR(3) NOT NULL COMMENT 'ISO 4217 currency code',
  currency_name VARCHAR(100) NOT NULL,
  currency_symbol VARCHAR(10),
  decimal_places TINYINT UNSIGNED NOT NULL DEFAULT 2,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  PRIMARY KEY (id),
  UNIQUE KEY uk_currency_code (currency_code),
  KEY idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create exchange_rates table
CREATE TABLE IF NOT EXISTS exchange_rates (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  from_currency_id BIGINT UNSIGNED NOT NULL,
  to_currency_id BIGINT UNSIGNED NOT NULL,
  rate DECIMAL(20, 6) NOT NULL,
  effective_date DATE NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  PRIMARY KEY (id),
  KEY idx_currencies (from_currency_id, to_currency_id, effective_date),
  
  CONSTRAINT fk_exchange_rates_from_currency
    FOREIGN KEY (from_currency_id)
    REFERENCES currencies(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  
  CONSTRAINT fk_exchange_rates_to_currency
    FOREIGN KEY (to_currency_id)
    REFERENCES currencies(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  
  CONSTRAINT chk_rate_positive
    CHECK (rate > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add currency support to transactions
ALTER TABLE transactions
  ADD COLUMN currency_id BIGINT UNSIGNED DEFAULT NULL AFTER description,
  ADD KEY idx_currency_id (currency_id),
  ADD CONSTRAINT fk_transactions_currency
    FOREIGN KEY (currency_id)
    REFERENCES currencies(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE;
