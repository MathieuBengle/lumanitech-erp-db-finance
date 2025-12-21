-- ============================================================================
-- Migration: V001__create_migration_tracking_table
-- Description: Create table to track applied migrations
-- Date: 2025-12-21
-- Author: System
-- ============================================================================

USE lumanitech_erp_finance;

CREATE TABLE IF NOT EXISTS schema_migrations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  version VARCHAR(50) NOT NULL,
  description VARCHAR(255) NOT NULL,
  script_name VARCHAR(255) NOT NULL,
  checksum VARCHAR(64),
  installed_by VARCHAR(100) NOT NULL,
  installed_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  execution_time INT UNSIGNED NOT NULL COMMENT 'Execution time in milliseconds',
  success BOOLEAN NOT NULL DEFAULT TRUE,
  
  PRIMARY KEY (id),
  UNIQUE KEY uk_version (version),
  KEY idx_installed_on (installed_on)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Tracks database migration versions';
