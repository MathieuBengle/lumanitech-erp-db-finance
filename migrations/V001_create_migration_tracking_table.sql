-- ============================================================================
-- Migration: V001_create_migration_tracking_table
-- Description: Create table to track applied migrations
-- Date: 2025-12-21
-- Author: System
-- ============================================================================

USE lumanitech_erp_finance;

CREATE TABLE IF NOT EXISTS schema_migrations (
  version VARCHAR(50) PRIMARY KEY,
  description VARCHAR(255),
  applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_applied_at (applied_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Tracks database migration versions';

-- ============================================================================
-- Self-tracking: Record this migration
-- ============================================================================

INSERT INTO schema_migrations (version, description)
VALUES ('V001', 'create_migration_tracking_table')
ON DUPLICATE KEY UPDATE applied_at = CURRENT_TIMESTAMP;
