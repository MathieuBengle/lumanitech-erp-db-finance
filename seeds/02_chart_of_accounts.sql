-- ============================================================================
-- Seed: Chart of Accounts - Sample Data
-- Description: Basic chart of accounts structure
-- ============================================================================

USE lumanitech_erp_finance;

-- Main account categories (parent accounts)
INSERT INTO accounts (account_code, account_name, account_type, parent_account_id, is_active, description) VALUES
-- Assets
('1000', 'Assets', 'ASSET', NULL, TRUE, 'All company assets'),
('1100', 'Current Assets', 'ASSET', NULL, TRUE, 'Assets convertible to cash within one year'),
('1200', 'Fixed Assets', 'ASSET', NULL, TRUE, 'Long-term tangible assets'),

-- Liabilities
('2000', 'Liabilities', 'LIABILITY', NULL, TRUE, 'All company liabilities'),
('2100', 'Current Liabilities', 'LIABILITY', NULL, TRUE, 'Obligations due within one year'),
('2200', 'Long-term Liabilities', 'LIABILITY', NULL, TRUE, 'Obligations due after one year'),

-- Equity
('3000', 'Equity', 'EQUITY', NULL, TRUE, 'Owner equity and retained earnings'),

-- Revenue
('4000', 'Revenue', 'REVENUE', NULL, TRUE, 'All income sources'),

-- Expenses
('5000', 'Expenses', 'EXPENSE', NULL, TRUE, 'All company expenses')
ON DUPLICATE KEY UPDATE
  account_name = VALUES(account_name),
  description = VALUES(description);

-- Detailed accounts
SET @current_assets_id = (SELECT id FROM accounts WHERE account_code = '1100');
SET @fixed_assets_id = (SELECT id FROM accounts WHERE account_code = '1200');
SET @current_liabilities_id = (SELECT id FROM accounts WHERE account_code = '2100');
SET @revenue_id = (SELECT id FROM accounts WHERE account_code = '4000');
SET @expenses_id = (SELECT id FROM accounts WHERE account_code = '5000');

INSERT INTO accounts (account_code, account_name, account_type, parent_account_id, is_active, description) VALUES
-- Current Assets Detail
('1110', 'Cash and Cash Equivalents', 'ASSET', @current_assets_id, TRUE, 'Cash on hand and in bank'),
('1120', 'Accounts Receivable', 'ASSET', @current_assets_id, TRUE, 'Money owed by customers'),
('1130', 'Inventory', 'ASSET', @current_assets_id, TRUE, 'Goods available for sale'),
('1140', 'Prepaid Expenses', 'ASSET', @current_assets_id, TRUE, 'Expenses paid in advance'),

-- Fixed Assets Detail
('1210', 'Property', 'ASSET', @fixed_assets_id, TRUE, 'Land and buildings'),
('1220', 'Equipment', 'ASSET', @fixed_assets_id, TRUE, 'Machinery and equipment'),
('1230', 'Vehicles', 'ASSET', @fixed_assets_id, TRUE, 'Company vehicles'),
('1240', 'Accumulated Depreciation', 'ASSET', @fixed_assets_id, TRUE, 'Cumulative depreciation on fixed assets'),

-- Current Liabilities Detail
('2110', 'Accounts Payable', 'LIABILITY', @current_liabilities_id, TRUE, 'Money owed to suppliers'),
('2120', 'Accrued Expenses', 'LIABILITY', @current_liabilities_id, TRUE, 'Expenses incurred but not yet paid'),
('2130', 'Short-term Loans', 'LIABILITY', @current_liabilities_id, TRUE, 'Loans due within one year'),

-- Revenue Detail
('4100', 'Sales Revenue', 'REVENUE', @revenue_id, TRUE, 'Income from sales'),
('4200', 'Service Revenue', 'REVENUE', @revenue_id, TRUE, 'Income from services'),
('4300', 'Other Revenue', 'REVENUE', @revenue_id, TRUE, 'Miscellaneous income'),

-- Expense Detail
('5100', 'Cost of Goods Sold', 'EXPENSE', @expenses_id, TRUE, 'Direct costs of goods sold'),
('5200', 'Salaries and Wages', 'EXPENSE', @expenses_id, TRUE, 'Employee compensation'),
('5300', 'Rent Expense', 'EXPENSE', @expenses_id, TRUE, 'Rent and lease payments'),
('5400', 'Utilities', 'EXPENSE', @expenses_id, TRUE, 'Electricity, water, internet'),
('5500', 'Office Supplies', 'EXPENSE', @expenses_id, TRUE, 'Office materials and supplies'),
('5600', 'Depreciation Expense', 'EXPENSE', @expenses_id, TRUE, 'Depreciation on fixed assets')
ON DUPLICATE KEY UPDATE
  account_name = VALUES(account_name),
  description = VALUES(description);
