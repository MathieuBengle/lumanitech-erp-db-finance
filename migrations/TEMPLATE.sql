-- ============================================================================
-- Migration: V###_description
-- Description: Brief description of what this migration does
-- Date: YYYY-MM-DD
-- Author: Your Name
-- ============================================================================

USE lumanitech_erp_finance;

-- Your SQL statements here
-- Example:
-- CREATE TABLE IF NOT EXISTS example_table (
--     id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
--     name VARCHAR(255) NOT NULL,
--     created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
--     PRIMARY KEY (id)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Self-tracking: Record this migration
-- ============================================================================

INSERT INTO schema_migrations (version, description)
VALUES ('V###', 'description')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;

-- ============================================================================
-- Rollback Notes (for reference only - not executed)
-- ============================================================================
-- To manually rollback this migration:
-- DROP TABLE IF EXISTS example_table;
-- DELETE FROM schema_migrations WHERE version = 'V###';
