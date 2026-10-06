<?php

/**
 * POST /admin/delete_product.php
 * ปิดใช้งานวัสดุ (ไม่ลบข้อมูลจริง)
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : id
 */

require_once __DIR__ . '/../bootstrap.php';

requireAdmin($conn);

$id = $_POST['id'] ?? '';

if ($id === '' || !is_numeric($id)) {
    responseError("Invalid Product ID");
}

$id = (int)$id;

$stmt = $conn->prepare("
    UPDATE products
    SET status = 'INACTIVE'
    WHERE id = ?
");

$stmt->bind_param("i", $id);
$stmt->execute();

responseSuccess([
    "message" => "ปิดใช้งานวัสดุสำเร็จ"
]);
