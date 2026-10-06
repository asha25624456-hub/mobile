<?php

/**
 * POST /admin/read_requisition.php
 * รายละเอียดใบเบิก 1 ใบ พร้อมรายการวัสดุและข้อมูลผู้เบิก
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : id
 */

require_once __DIR__ . '/../bootstrap.php';

requireAdmin($conn);

$id = $_POST['id'] ?? '';

if ($id === '' || !is_numeric($id)) {
    responseError("Invalid Requisition ID");
}

$id = (int)$id;

$stmt = $conn->prepare("
    SELECT
        r.*,
        u.employee_code,
        u.name AS requester_name,
        u.email AS requester_email
    FROM requisitions r
    INNER JOIN users u
        ON u.id = r.requester_id
    WHERE r.id = ?
    LIMIT 1
");

$stmt->bind_param("i", $id);
$stmt->execute();

$request = $stmt->get_result()->fetch_assoc();

if (!$request) {
    responseError("ไม่พบใบเบิก");
}

$stmt = $conn->prepare("
    SELECT
        ri.id,
        ri.product_id,
        p.sku,
        p.product_name,
        ri.requested_quantity,
        ri.approved_quantity,
        ri.picked_quantity,
        ri.issued_quantity,
        ri.unit,
        ri.status
    FROM requisition_items ri
    INNER JOIN products p
        ON p.id = ri.product_id
    WHERE ri.requisition_id = ?
    ORDER BY ri.id ASC
");

$stmt->bind_param("i", $id);
$stmt->execute();

$items = [];

$result = $stmt->get_result();

while ($row = $result->fetch_assoc()) {
    $items[] = $row;
}

$request['items'] = $items;

$stmt = $conn->prepare("\n    SELECT pickup_code, status AS pickup_status\n    FROM pickups\n    WHERE requisition_id = ?\n    LIMIT 1\n");
$stmt->bind_param("i", $id);
$stmt->execute();
$pickup = $stmt->get_result()->fetch_assoc();
$request['pickup'] = $pickup ?: null;

responseSuccess([
    "data" => $request
]);
