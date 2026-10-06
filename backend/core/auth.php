<?php

/**
 * อ่าน Token และตรวจสิทธิ์ (User / Admin)
 */

function getToken()
{
    $header = $_SERVER['HTTP_AUTHORIZATION']
        ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
        ?? '';

    if ($header === '' && function_exists('getallheaders')) {
        foreach (getallheaders() as $name => $value) {
            if (strcasecmp($name, 'Authorization') === 0) {
                $header = $value;
                break;
            }
        }
    }

    if (preg_match('/Bearer\s+(.+)/i', $header, $matches)) {
        return trim($matches[1]);
    }

    return $_POST['token'] ?? $_GET['token'] ?? '';
}

function requireUser($conn)
{
    $token = getToken();

    if ($token === '') {
        responseError("กรุณาเข้าสู่ระบบ");
    }

    $tokenHash = hash("sha256", $token);

    $stmt = $conn->prepare("
        SELECT
            users.id,
            users.employee_code,
            users.name,
            users.email,
            users.account_status
        FROM user_sessions
        INNER JOIN users
            ON users.id = user_sessions.user_id
        WHERE user_sessions.session_token = ?
          AND user_sessions.expires_at > NOW()
          AND user_sessions.revoked_at IS NULL
          AND users.account_status = 'ACTIVE'
        LIMIT 1
    ");

    $stmt->bind_param("s", $tokenHash);
    $stmt->execute();

    $user = $stmt->get_result()->fetch_assoc();

    if (!$user) {
        responseError("Session ไม่ถูกต้องหรือหมดอายุ");
    }

    return $user;
}

function requireAdmin($conn)
{
    $token = getToken();

    if ($token === '') {
        responseError("กรุณาเข้าสู่ระบบ Admin");
    }

    $tokenHash = hash("sha256", $token);

    $stmt = $conn->prepare("
        SELECT
            admins.id,
            admins.username,
            admins.name,
            admins.email,
            admins.account_status
        FROM admin_sessions
        INNER JOIN admins
            ON admins.id = admin_sessions.admin_id
        WHERE admin_sessions.session_token = ?
          AND admin_sessions.expires_at > NOW()
          AND admin_sessions.revoked_at IS NULL
          AND admins.account_status = 'ACTIVE'
        LIMIT 1
    ");

    $stmt->bind_param("s", $tokenHash);
    $stmt->execute();

    $admin = $stmt->get_result()->fetch_assoc();

    if (!$admin) {
        responseError("Admin Session ไม่ถูกต้องหรือหมดอายุ");
    }

    return $admin;
}
