<?php

/**
 * POST /admin/read_status_logs.php
 * ประวัติการเปลี่ยนสถานะของใบเบิกใดก็ได้
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : requisition_id
 */

require_once __DIR__ . '/../bootstrap.php';

requireAdmin($conn);

$id = $_POST['requisition_id'] ?? '';

if ($id === '' || !is_numeric($id)) {
    responseError("Invalid Requisition ID");
}

$id = (int)$id;

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
