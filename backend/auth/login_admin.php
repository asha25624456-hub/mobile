<?php

/**
 * POST /auth/login_admin.php
 * เข้าสู่ระบบผู้ดูแลระบบด้วย Username แล้วได้ token
 *
 * สิทธิ์   : ไม่ต้องล็อกอิน
 * รับค่า   : username, password
 */

require_once __DIR__ . '/../bootstrap.php';

$username = trim($_POST['username'] ?? '');
$password = $_POST['password'] ?? '';

if ($username === '' || $password === '') {
    responseError("กรุณากรอก Username และ Password");
}

$stmt = $conn->prepare("
    SELECT
        id,
        username,
        name,
        email,
        password_hash,
        account_status
    FROM admins
    WHERE username = ?
    LIMIT 1
");

$stmt->bind_param("s", $username);
$stmt->execute();

$admin = $stmt->get_result()->fetch_assoc();

if (!$admin) {
    responseError("Username หรือ Password ไม่ถูกต้อง");
}

if ($admin['account_status'] !== 'ACTIVE') {
    responseError("บัญชี Admin ไม่สามารถใช้งานได้");
}

if (!password_verify($password, $admin['password_hash'])) {

    $stmt = $conn->prepare("
        UPDATE admins
        SET failed_login_attempts = failed_login_attempts + 1
        WHERE id = ?
    ");

    $stmt->bind_param("i", $admin['id']);
    $stmt->execute();

    responseError("Username หรือ Password ไม่ถูกต้อง");
}

$ip = $_SERVER['REMOTE_ADDR'] ?? '';
$userAgent = $_SERVER['HTTP_USER_AGENT'] ?? '';

$stmt = $conn->prepare("
    UPDATE admins
    SET
        failed_login_attempts = 0,
        last_login_at = NOW(),
        last_login_ip = ?
    WHERE id = ?
");

$stmt->bind_param("si", $ip, $admin['id']);
$stmt->execute();

$plainToken = bin2hex(random_bytes(32));
$tokenHash = hash("sha256", $plainToken);
$expiresAt = date("Y-m-d H:i:s", time() + 604800);

$stmt = $conn->prepare("
    INSERT INTO admin_sessions
    (
        admin_id,
        session_token,
        ip_address,
        user_agent,
        expires_at
    )
    VALUES (?, ?, ?, ?, ?)
");

$stmt->bind_param(
    "issss",
    $admin['id'],
    $tokenHash,
    $ip,
    $userAgent,
    $expiresAt
);

$stmt->execute();

responseSuccess([
    "token" => $plainToken,
    "expires_at" => $expiresAt,
    "admin" => [
        "id" => (int)$admin['id'],
        "username" => $admin['username'],
        "name" => $admin['name'],
        "email" => $admin['email']
    ]
]);
