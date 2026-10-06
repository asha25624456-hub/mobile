<?php

/**
 * POST /admin/read_categories.php
 * รายการหมวดหมู่วัสดุที่เปิดใช้งาน (ใช้เลือกหมวดหมู่ตอนเพิ่ม/แก้ไขวัสดุ)
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : -
 */

require_once __DIR__ . '/../bootstrap.php';

requireAdmin($conn);

$result = $conn->query("
    SELECT
        id,
        category_code,
        category_name,
        description,
        status
    FROM categories
    WHERE status = 'ACTIVE'
    ORDER BY category_name ASC
");

$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

responseSuccess([
    "data" => $data
]);
