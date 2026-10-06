<?php

/**
 * POST /admin/mark_notification_read.php
 * ทำเครื่องหมายว่าอ่านการแจ้งเตือนแล้ว
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : id
 */

require_once __DIR__ . '/../bootstrap.php';

$admin = requireAdmin($conn);

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
      AND admin_id = ?
");

$stmt->bind_param(
    "ii",
    $notificationId,
    $admin['id']
);

$stmt->execute();

responseSuccess([
    "message" => "อ่านการแจ้งเตือนแล้ว"
]);
