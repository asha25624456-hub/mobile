-- MySQL only. Back up before running.
-- Run after migrations 001 and 002 on databases that already contain requisitions.
ALTER TABLE products
  ADD COLUMN reserved_quantity INT UNSIGNED NOT NULL DEFAULT 0 AFTER stock_quantity;

-- Pending requisitions begin reserving their requested quantities.
UPDATE products AS p
LEFT JOIN (
  SELECT ri.product_id, SUM(ri.requested_quantity) AS reserved_total
  FROM requisition_items AS ri
  INNER JOIN requisitions AS r ON r.id = ri.requisition_id
  WHERE r.status = 'PENDING'
  GROUP BY ri.product_id
) AS pending ON pending.product_id = p.id
SET p.reserved_quantity = COALESCE(pending.reserved_total, 0);

-- Review rows returned here. Legacy pending requests may collectively exceed physical stock.
SELECT id, sku, product_name, stock_quantity, reserved_quantity
FROM products
WHERE reserved_quantity > stock_quantity;
