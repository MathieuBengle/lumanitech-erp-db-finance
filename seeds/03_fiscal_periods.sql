-- ============================================================================
-- Seed: Fiscal Periods
-- Description: Create fiscal periods for current year
-- ============================================================================

USE lumanitech_erp_finance;

-- Fiscal periods for 2025 (monthly)
INSERT INTO fiscal_periods (period_code, period_name, start_date, end_date, fiscal_year, is_closed) VALUES
('2025-01', 'January 2025', '2025-01-01', '2025-01-31', 2025, FALSE),
('2025-02', 'February 2025', '2025-02-01', '2025-02-28', 2025, FALSE),
('2025-03', 'March 2025', '2025-03-01', '2025-03-31', 2025, FALSE),
('2025-04', 'April 2025', '2025-04-01', '2025-04-30', 2025, FALSE),
('2025-05', 'May 2025', '2025-05-01', '2025-05-31', 2025, FALSE),
('2025-06', 'June 2025', '2025-06-01', '2025-06-30', 2025, FALSE),
('2025-07', 'July 2025', '2025-07-01', '2025-07-31', 2025, FALSE),
('2025-08', 'August 2025', '2025-08-01', '2025-08-31', 2025, FALSE),
('2025-09', 'September 2025', '2025-09-01', '2025-09-30', 2025, FALSE),
('2025-10', 'October 2025', '2025-10-01', '2025-10-31', 2025, FALSE),
('2025-11', 'November 2025', '2025-11-01', '2025-11-30', 2025, FALSE),
('2025-12', 'December 2025', '2025-12-01', '2025-12-31', 2025, FALSE)
ON DUPLICATE KEY UPDATE
  period_name = VALUES(period_name),
  start_date = VALUES(start_date),
  end_date = VALUES(end_date);
