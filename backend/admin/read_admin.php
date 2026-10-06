<?php

/**
 * POST /admin/read_admin.php
 * ดูข้อมูลผู้ดูแลที่ล็อกอินอยู่ (ใช้ตรวจว่า session ยังใช้ได้)
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : -
 */

require_once __DIR__ . '/../bootstrap.php';

$admin = requireAdmin($conn);

responseSuccess([
    "admin" => [
        "id" => (int)$admin['id'],
        "username" => $admin['username'],
        "name" => $admin['name'],
        "email" => $admin['email']
    ]
]);
