<?php

/**
 * POST /admin/read_notifications.php
 * การแจ้งเตือนของ Admin
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : -
 */

require_once __DIR__ . '/../bootstrap.php';

$admin = requireAdmin($conn);

$stmt = $conn->prepare("
    SELECT *
    FROM notifications
    WHERE admin_id = ?
    ORDER BY created_at DESC
");

$stmt->bind_param("i", $admin['id']);
$stmt->execute();

$result = $stmt->get_result();
$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

responseSuccess([
    "data" => $data
]);
