-- MySQL only. Back up the database before running.
-- Detail stages move to pickups/pickup_items; the requisition itself keeps 5 states.
ALTER TABLE requisitions
  MODIFY status ENUM(
    'DRAFT','PENDING','APPROVED','REJECTED','PREPARING','READY','COMPLETED','CANCELLED','ISSUED'
  ) NOT NULL DEFAULT 'PENDING';

UPDATE requisitions
SET status = CASE
  WHEN status = 'DRAFT' THEN 'PENDING'
  WHEN status IN ('PREPARING','READY') THEN 'APPROVED'
  WHEN status = 'COMPLETED' THEN 'ISSUED'
  ELSE status
END;

ALTER TABLE requisitions
  MODIFY status ENUM('PENDING','APPROVED','ISSUED','CANCELLED','REJECTED')
  NOT NULL DEFAULT 'PENDING';
