<?php

/**
 * POST /user/read_user.php
 * ดูข้อมูลผู้ใช้ที่ล็อกอินอยู่ (ใช้ตรวจว่า session ยังใช้ได้)
 *
 * สิทธิ์   : User (Authorization: Bearer <token>)
 * รับค่า   : -
 */

require_once __DIR__ . '/../bootstrap.php';

$user = requireUser($conn);

responseSuccess([
    "user" => [
        "id" => (int)$user['id'],
        "employee_code" => $user['employee_code'],
        "name" => $user['name'],
        "email" => $user['email']
    ]
]);
