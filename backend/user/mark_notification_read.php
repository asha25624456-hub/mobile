<?php

/**
 * POST /user/mark_notification_read.php
 * ทำเครื่องหมายว่าอ่านการแจ้งเตือนแล้ว
 *
 * สิทธิ์   : User (Authorization: Bearer <token>)
 * รับค่า   : id
 */

require_once __DIR__ . '/../bootstrap.php';

$user = requireUser($conn);

$notificationId = $_POST['id'] ?? '';

if ($notificationId === '' ||
    !is_numeric($notificationId)) {
    responseError("Invalid Notification ID");
}

$notificationId = (int)$notificationId;

$stmt = $conn->prepare("
    UPDATE notifications
    SET
        is_read = TRUE,
        read_at = NOW()
    WHERE id = ?
      AND user_id = ?
");

$stmt->bind_param(
    "ii",
    $notificationId,
    $user['id']
);

$stmt->execute();

responseSuccess([
    "message" => "อ่านการแจ้งเตือนแล้ว"
]);
