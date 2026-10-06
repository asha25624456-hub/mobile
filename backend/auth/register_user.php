<?php

/**
 * POST /auth/register_user.php
 * สมัครสมาชิก (ผู้เบิกวัสดุ)
 *
 * สิทธิ์   : ไม่ต้องล็อกอิน
 * รับค่า   : employee_code, name, email, password
 */

require_once __DIR__ . '/../bootstrap.php';

$employeeCode = trim($_POST['employee_code'] ?? '');
$name = trim($_POST['name'] ?? '');
$email = strtolower(trim($_POST['email'] ?? ''));
$password = $_POST['password'] ?? '';

if (
    $employeeCode === '' ||
    $name === '' ||
    $email === '' ||
    $password === ''
) {
    responseError("กรุณากรอกข้อมูลให้ครบถ้วน");
}

if (mb_strlen($employeeCode) > 50) {
    responseError("รหัสพนักงานต้องไม่เกิน 50 ตัวอักษร");
}

if (mb_strlen($name) > 150) {
    responseError("ชื่อต้องไม่เกิน 150 ตัวอักษร");
}

if (
    strlen($email) > 150 ||
    !filter_var($email, FILTER_VALIDATE_EMAIL)
) {
    responseError("รูปแบบอีเมลไม่ถูกต้อง");
}

if (strlen($password) < 8) {
    responseError("รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร");
}

if (strlen($password) > 72) {
    responseError("รหัสผ่านต้องไม่เกิน 72 ตัวอักษร");
}

$stmt = $conn->prepare("
    SELECT employee_code, email
    FROM users
    WHERE employee_code = ?
       OR email = ?
    LIMIT 2
");

$stmt->bind_param("ss", $employeeCode, $email);
$stmt->execute();

$existing = $stmt->get_result();

while ($row = $existing->fetch_assoc()) {

    if (strcasecmp($row['employee_code'], $employeeCode) === 0) {
        responseError("รหัสพนักงานนี้ถูกใช้งานแล้ว");
    }

    responseError("อีเมลนี้ถูกใช้งานแล้ว");
}

$passwordHash = password_hash($password, PASSWORD_DEFAULT);

try {

    $stmt = $conn->prepare("
        INSERT INTO users
        (
            employee_code,
            name,
            email,
            password_hash
        )
        VALUES (?, ?, ?, ?)
    ");

    $stmt->bind_param(
        "ssss",
        $employeeCode,
        $name,
        $email,
        $passwordHash
    );

    $stmt->execute();
} catch (mysqli_sql_exception $e) {

    if ($e->getCode() === 1062) {
        responseError("รหัสพนักงานหรืออีเมลนี้ถูกใช้งานแล้ว");
    }

    throw $e;
}

responseSuccess([
    "message" => "สมัครสมาชิกสำเร็จ",
    "user" => [
        "id" => (int)$stmt->insert_id,
        "employee_code" => $employeeCode,
        "name" => $name,
        "email" => $email
    ]
]);
