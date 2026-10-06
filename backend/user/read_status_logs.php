<?php

/**
 * POST /user/read_status_logs.php
 * ประวัติการเปลี่ยนสถานะของใบเบิกตัวเอง
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

// User ดูได้เฉพาะใบเบิกของตัวเอง
$stmt = $conn->prepare("
    SELECT id
    FROM requisitions
    WHERE id = ?
      AND requester_id = ?
    LIMIT 1
");

$stmt->bind_param("ii", $id, $user['id']);
$stmt->execute();

if (!$stmt->get_result()->fetch_assoc()) {
    responseError("ไม่มีสิทธิ์ดูข้อมูลนี้");
}

$stmt = $conn->prepare("
    SELECT *
    FROM requisition_status_logs
    WHERE requisition_id = ?
    ORDER BY created_at ASC
");

$stmt->bind_param("i", $id);
$stmt->execute();

$result = $stmt->get_result();
$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

responseSuccess([
    "data" => $data
]);
