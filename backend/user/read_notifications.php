<?php

/**
 * POST /user/read_notifications.php
 * การแจ้งเตือนของตัวเอง
 *
 * สิทธิ์   : User (Authorization: Bearer <token>)
 * รับค่า   : -
 */

require_once __DIR__ . '/../bootstrap.php';

$user = requireUser($conn);

$stmt = $conn->prepare("
    SELECT *
    FROM notifications
    WHERE user_id = ?
    ORDER BY created_at DESC
");

$stmt->bind_param("i", $user['id']);
$stmt->execute();

$result = $stmt->get_result();
$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

responseSuccess([
    "data" => $data
]);
