<?php

/**
 * POST /user/read_pickup.php
 * ดูรหัส / QR สำหรับรับวัสดุของใบเบิกตัวเอง
 *
 * สิทธิ์   : User (Authorization: Bearer <token>)
 * รับค่า   : requisition_id
 */

require_once __DIR__ . '/../bootstrap.php';

$user = requireUser($conn);

$id = $_POST['requisition_id'] ?? '';

if ($id === '' || !is_numeric($id)) {
    responseError("Invalid Requisition ID");
}

$id = (int)$id;

$stmt = $conn->prepare("
    SELECT
        p.id,
        p.requisition_id,
        p.pickup_code,
        p.qr_token,
        p.status,
        p.prepared_at,
        p.picked_up_at
    FROM pickups p
    INNER JOIN requisitions r
        ON r.id = p.requisition_id
    WHERE p.requisition_id = ?
      AND r.requester_id = ?
    LIMIT 1
");

$stmt->bind_param(
    "ii",
    $id,
    $user['id']
);

$stmt->execute();

$pickup = $stmt->get_result()->fetch_assoc();

if (!$pickup) {
    responseError("ไม่พบข้อมูลรับวัสดุ");
}

responseSuccess([
    "data" => $pickup
]);
