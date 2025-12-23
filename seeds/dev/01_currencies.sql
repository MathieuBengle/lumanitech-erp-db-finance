-- ============================================================================
-- Seed: Default Currencies
-- Description: Insert commonly used currencies
-- ============================================================================

USE lumanitech_erp_finance;

INSERT INTO currencies (currency_code, currency_name, currency_symbol, decimal_places, is_active) VALUES
('USD', 'US Dollar', '$', 2, TRUE),
('EUR', 'Euro', '€', 2, TRUE),
('GBP', 'British Pound', '£', 2, TRUE),
('CAD', 'Canadian Dollar', 'C$', 2, TRUE),
('CHF', 'Swiss Franc', 'CHF', 2, TRUE),
('JPY', 'Japanese Yen', '¥', 0, TRUE),
('CNY', 'Chinese Yuan', '¥', 2, TRUE),
('XAF', 'CFA Franc BEAC', 'FCFA', 0, TRUE)
ON DUPLICATE KEY UPDATE
  currency_name = VALUES(currency_name),
  currency_symbol = VALUES(currency_symbol),
  decimal_places = VALUES(decimal_places),
  is_active = VALUES(is_active);
