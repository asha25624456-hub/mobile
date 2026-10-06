<?php

require_once __DIR__ . '/../bootstrap.php';

$admin = requireAdmin($conn);
$currentPassword = $_POST['current_password'] ?? '';
$newPassword = $_POST['new_password'] ?? '';
$confirmPassword = $_POST['confirm_password'] ?? '';

if ($currentPassword === '' || $newPassword === '' || $confirmPassword === '') {
    responseError('กรุณากรอกรหัสผ่านให้ครบทุกช่อง');
}

if (strlen($newPassword) < 12 || strlen($newPassword) > 72) {
    responseError('รหัสผ่านใหม่ต้องมีความยาว 12 ถึง 72 ตัวอักษร');
}

if ($newPassword !== $confirmPassword) {
    responseError('รหัสผ่านใหม่และการยืนยันไม่ตรงกัน');
}

$stmt = $conn->prepare('SELECT password_hash FROM admins WHERE id = ? LIMIT 1');
$stmt->bind_param('i', $admin['id']);
$stmt->execute();
$account = $stmt->get_result()->fetch_assoc();

if (!$account || !password_verify($currentPassword, $account['password_hash'])) {
    responseError('รหัสผ่านปัจจุบันไม่ถูกต้อง');
}

$passwordHash = password_hash($newPassword, PASSWORD_DEFAULT);
$conn->begin_transaction();

try {
    $stmt = $conn->prepare('UPDATE admins SET password_hash = ? WHERE id = ?');
    $stmt->bind_param('si', $passwordHash, $admin['id']);
    $stmt->execute();

    // Require a fresh login on every device after changing the password.
    $stmt = $conn->prepare(
        'UPDATE admin_sessions SET revoked_at = NOW() WHERE admin_id = ? AND revoked_at IS NULL'
    );
    $stmt->bind_param('i', $admin['id']);
    $stmt->execute();

    $conn->commit();
    responseSuccess(['message' => 'เปลี่ยนรหัสผ่านสำเร็จ กรุณาเข้าสู่ระบบใหม่']);
} catch (Throwable $e) {
    $conn->rollback();
    responseError(safeMessage($e));
}
