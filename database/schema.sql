-- Smart Requisition schema for MySQL 8.0+ / MariaDB 10.5+
-- Run against the configured database after taking a backup.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  employee_code VARCHAR(50) NOT NULL,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  account_status ENUM('ACTIVE','INACTIVE','SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
  failed_login_attempts INT UNSIGNED NOT NULL DEFAULT 0,
  last_login_at DATETIME NULL,
  last_login_ip VARCHAR(45) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_users_employee_code (employee_code), UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS admins (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  username VARCHAR(100) NOT NULL,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  account_status ENUM('ACTIVE','INACTIVE','SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
  failed_login_attempts INT UNSIGNED NOT NULL DEFAULT 0,
  last_login_at DATETIME NULL,
  last_login_ip VARCHAR(45) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_admins_username (username), UNIQUE KEY uq_admins_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_sessions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, user_id BIGINT UNSIGNED NOT NULL,
  session_token CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  ip_address VARCHAR(45) NULL, user_agent VARCHAR(512) NULL,
  expires_at DATETIME NOT NULL, revoked_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_user_sessions_token (session_token),
  KEY ix_user_sessions_user_expiry (user_id, expires_at),
  CONSTRAINT fk_user_sessions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS admin_sessions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, admin_id BIGINT UNSIGNED NOT NULL,
  session_token CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  ip_address VARCHAR(45) NULL, user_agent VARCHAR(512) NULL,
  expires_at DATETIME NOT NULL, revoked_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_admin_sessions_token (session_token),
  KEY ix_admin_sessions_admin_expiry (admin_id, expires_at),
  CONSTRAINT fk_admin_sessions_admin FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS categories (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, category_code VARCHAR(40) NOT NULL, category_name VARCHAR(120) NOT NULL,
  description TEXT NULL, status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_categories_code (category_code), UNIQUE KEY uq_categories_name (category_name), KEY ix_categories_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS products (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, sku VARCHAR(64) NOT NULL,
  product_name VARCHAR(180) NOT NULL, description TEXT NULL, category_id BIGINT UNSIGNED NULL,
  unit VARCHAR(40) NOT NULL, image_url VARCHAR(2048) NULL,
  minimum_stock INT UNSIGNED NOT NULL DEFAULT 0, maximum_stock INT UNSIGNED NOT NULL DEFAULT 0,
  stock_quantity INT UNSIGNED NOT NULL DEFAULT 0,
  reserved_quantity INT UNSIGNED NOT NULL DEFAULT 0,
  status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_products_sku (sku), KEY ix_products_category_status (category_id,status),
  KEY ix_products_name (product_name),
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS requisitions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, request_no VARCHAR(40) NOT NULL,
  requester_id BIGINT UNSIGNED NOT NULL, purpose TEXT NULL, required_date DATE NULL,
  status ENUM('PENDING','APPROVED','ISSUED','CANCELLED','REJECTED') NOT NULL DEFAULT 'PENDING',
  total_items INT UNSIGNED NOT NULL DEFAULT 0, total_quantity INT UNSIGNED NOT NULL DEFAULT 0,
  rejection_comment TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_requisitions_request_no (request_no),
  KEY ix_requisitions_requester_created (requester_id,created_at), KEY ix_requisitions_status_created (status,created_at),
  CONSTRAINT fk_requisitions_requester FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS requisition_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, requisition_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL, requested_quantity INT UNSIGNED NOT NULL,
  approved_quantity INT UNSIGNED NOT NULL DEFAULT 0, picked_quantity INT UNSIGNED NOT NULL DEFAULT 0,
  issued_quantity INT UNSIGNED NOT NULL DEFAULT 0, unit VARCHAR(40) NOT NULL,
  status ENUM('PENDING','APPROVED','REJECTED','PICKING','PICKED','ISSUED') NOT NULL DEFAULT 'PENDING',
  PRIMARY KEY (id), KEY ix_req_items_requisition (requisition_id), KEY ix_req_items_product (product_id),
  CONSTRAINT fk_req_items_requisition FOREIGN KEY (requisition_id) REFERENCES requisitions(id) ON DELETE CASCADE,
  CONSTRAINT fk_req_items_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
  CONSTRAINT chk_req_item_requested CHECK (requested_quantity > 0),
  CONSTRAINT chk_req_item_approved CHECK (approved_quantity <= requested_quantity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pickups (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, requisition_id BIGINT UNSIGNED NOT NULL,
  pickup_code VARCHAR(40) NOT NULL, qr_token CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  status ENUM('READY','PICKED_UP','CANCELLED') NOT NULL DEFAULT 'READY',
  prepared_at DATETIME NULL, picked_up_at DATETIME NULL, confirmed_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), UNIQUE KEY uq_pickups_requisition (requisition_id), UNIQUE KEY uq_pickups_code (pickup_code),
  UNIQUE KEY uq_pickups_qr (qr_token), KEY ix_pickups_status (status),
  CONSTRAINT fk_pickups_requisition FOREIGN KEY (requisition_id) REFERENCES requisitions(id) ON DELETE CASCADE,
  CONSTRAINT fk_pickups_admin FOREIGN KEY (confirmed_by) REFERENCES admins(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS requisition_status_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, requisition_id BIGINT UNSIGNED NOT NULL,
  from_status VARCHAR(24) NULL, to_status VARCHAR(24) NOT NULL,
  changed_by_user BIGINT UNSIGNED NULL, changed_by_admin BIGINT UNSIGNED NULL,
  comment TEXT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), KEY ix_status_logs_req_created (requisition_id,created_at),
  CONSTRAINT fk_status_logs_req FOREIGN KEY (requisition_id) REFERENCES requisitions(id) ON DELETE CASCADE,
  CONSTRAINT fk_status_logs_user FOREIGN KEY (changed_by_user) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_status_logs_admin FOREIGN KEY (changed_by_admin) REFERENCES admins(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inventory_transactions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, product_id BIGINT UNSIGNED NOT NULL,
  transaction_type ENUM('IN','OUT','ADJUSTMENT') NOT NULL, quantity INT UNSIGNED NOT NULL,
  before_quantity INT UNSIGNED NOT NULL, after_quantity INT UNSIGNED NOT NULL,
  reference_type VARCHAR(32) NULL, reference_id BIGINT UNSIGNED NULL, created_by BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), KEY ix_inventory_tx_product_created (product_id,created_at),
  KEY ix_inventory_tx_reference (reference_type,reference_id),
  CONSTRAINT fk_inventory_tx_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
  CONSTRAINT fk_inventory_tx_admin FOREIGN KEY (created_by) REFERENCES admins(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notifications (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, user_id BIGINT UNSIGNED NULL, admin_id BIGINT UNSIGNED NULL,
  title VARCHAR(180) NOT NULL, message TEXT NOT NULL, type VARCHAR(32) NULL,
  reference_type VARCHAR(32) NULL, reference_id BIGINT UNSIGNED NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0, read_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id), KEY ix_notifications_user_created (user_id,created_at),
  KEY ix_notifications_admin_created (admin_id,created_at),
  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_notifications_admin FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE,
  CONSTRAINT chk_notification_recipient CHECK ((user_id IS NOT NULL) <> (admin_id IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
