-- Upgrade an existing installation after taking a verified database backup.
-- This migration copies each current inventory quantity onto its product, then
-- removes the now-redundant one-to-one inventory table.
-- MySQL DDL may auto-commit; do not treat this as a rollbackable transaction.

ALTER TABLE products
  ADD COLUMN stock_quantity INT UNSIGNED NOT NULL DEFAULT 0 AFTER maximum_stock;

UPDATE products AS p
LEFT JOIN inventory AS i ON i.product_id = p.id
SET p.stock_quantity = COALESCE(i.quantity, 0);

DROP TABLE inventory;
