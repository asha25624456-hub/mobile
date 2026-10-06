<?php

/**
 * POST /auth/logout_admin.php
 * ออกจากระบบ (ยกเลิก session ของผู้ดูแลระบบ)
 *
 * สิทธิ์   : ส่ง Admin Token (Authorization: Bearer <token>)
 * รับค่า   : -
 */

require_once __DIR__ . '/../bootstrap.php';

$token = getToken();

if ($token === '') {
    responseError("ไม่พบ Admin Session");
}

$tokenHash = hash("sha256", $token);

$stmt = $conn->prepare("
    UPDATE admin_sessions
    SET revoked_at = NOW()
    WHERE session_token = ?
      AND revoked_at IS NULL
");

$stmt->bind_param("s", $tokenHash);
$stmt->execute();

responseSuccess([
    "message" => "ออกจากระบบ Admin สำเร็จ"
]);
