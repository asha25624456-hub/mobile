<?php

/**
 * POST /auth/logout_user.php
 * ออกจากระบบ (ยกเลิก session ของผู้เบิกวัสดุ)
 *
 * สิทธิ์   : ส่ง User Token (Authorization: Bearer <token>)
 * รับค่า   : -
 */

require_once __DIR__ . '/../bootstrap.php';

$token = getToken();

if ($token === '') {
    responseError("ไม่พบ Session");
}

$tokenHash = hash("sha256", $token);

$stmt = $conn->prepare("
    UPDATE user_sessions
    SET revoked_at = NOW()
    WHERE session_token = ?
      AND revoked_at IS NULL
");

$stmt->bind_param("s", $tokenHash);
$stmt->execute();

responseSuccess([
    "message" => "ออกจากระบบสำเร็จ"
]);
