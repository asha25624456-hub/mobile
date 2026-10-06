<?php

/**
 * POST /auth/login_user.php
 * เข้าสู่ระบบผู้เบิกวัสดุด้วยรหัสพนักงาน แล้วได้ token
 *
 * สิทธิ์   : ไม่ต้องล็อกอิน
 * รับค่า   : employee_code, password
 */

require_once __DIR__ . '/../bootstrap.php';

$employeeCode = trim($_POST['employee_code'] ?? '');
$password = $_POST['password'] ?? '';

if ($employeeCode === '' || $password === '') {
    responseError("กรุณากรอกรหัสพนักงานและรหัสผ่าน");
}

$stmt = $conn->prepare("
    SELECT
        id,
        employee_code,
        name,
        email,
        password_hash,
        account_status
    FROM users
    WHERE employee_code = ?
    LIMIT 1
");

$stmt->bind_param("s", $employeeCode);
$stmt->execute();

$user = $stmt->get_result()->fetch_assoc();

if (!$user) {
    responseError("รหัสพนักงานหรือรหัสผ่านไม่ถูกต้อง");
}

if ($user['account_status'] !== 'ACTIVE') {
    responseError("บัญชีผู้ใช้งานไม่สามารถใช้งานได้");
}

if (!password_verify($password, $user['password_hash'])) {

    $stmt = $conn->prepare("
        UPDATE users
        SET failed_login_attempts = failed_login_attempts + 1
        WHERE id = ?
    ");

    $stmt->bind_param("i", $user['id']);
    $stmt->execute();

    responseError("รหัสพนักงานหรือรหัสผ่านไม่ถูกต้อง");
}

$ip = $_SERVER['REMOTE_ADDR'] ?? '';
$userAgent = $_SERVER['HTTP_USER_AGENT'] ?? '';

$stmt = $conn->prepare("
    UPDATE users
    SET
        failed_login_attempts = 0,
        last_login_at = NOW(),
        last_login_ip = ?
    WHERE id = ?
");

$stmt->bind_param("si", $ip, $user['id']);
$stmt->execute();

$plainToken = bin2hex(random_bytes(32));
$tokenHash = hash("sha256", $plainToken);
$expiresAt = date("Y-m-d H:i:s", time() + 604800);

$stmt = $conn->prepare("
    INSERT INTO user_sessions
    (
        user_id,
        session_token,
        ip_address,
        user_agent,
        expires_at
    )
    VALUES (?, ?, ?, ?, ?)
");

$stmt->bind_param(
    "issss",
    $user['id'],
    $tokenHash,
    $ip,
    $userAgent,
    $expiresAt
);

$stmt->execute();

responseSuccess([
    "token" => $plainToken,
    "expires_at" => $expiresAt,
    "user" => [
        "id" => (int)$user['id'],
        "employee_code" => $user['employee_code'],
        "name" => $user['name'],
        "email" => $user['email']
    ]
]);
