<?php

/**
 * POST /admin/create_product.php
 * เพิ่มวัสดุใหม่ (สร้าง inventory จำนวน 0 ให้อัตโนมัติ)
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : sku, product_name, description, category_id, unit, image_url, minimum_stock, maximum_stock
 */

require_once __DIR__ . '/../bootstrap.php';

$admin = requireAdmin($conn);

$sku = trim($_POST['sku'] ?? '');
$productName = trim($_POST['product_name'] ?? '');
$description = trim($_POST['description'] ?? '');
$categoryId = $_POST['category_id'] ?? '';
$unit = trim($_POST['unit'] ?? '');
$imageUrl = trim($_POST['image_url'] ?? '');
$minimumStock = $_POST['minimum_stock'] ?? 0;
$maximumStock = $_POST['maximum_stock'] ?? 0;

if ($sku === '') {
    responseError("กรุณากรอก SKU");
}

if ($productName === '') {
    responseError("กรุณากรอกชื่อวัสดุ");
}

if ($unit === '') {
    responseError("กรุณากรอกหน่วย");
}

if ($categoryId !== '' && !is_numeric($categoryId)) {
    responseError("Invalid Category ID");
}

if (!is_numeric($minimumStock) || $minimumStock < 0) {
    responseError("Minimum Stock ไม่ถูกต้อง");
}

if (!is_numeric($maximumStock) || $maximumStock < 0) {
    responseError("Maximum Stock ไม่ถูกต้อง");
}

$categoryId = $categoryId === ''
    ? null
    : (int)$categoryId;

$minimumStock = (int)$minimumStock;
$maximumStock = (int)$maximumStock;

if ($maximumStock > 0 && $maximumStock < $minimumStock) {
    responseError("Maximum Stock ต้องมากกว่าหรือเท่ากับ Minimum Stock");
}

$conn->begin_transaction();

try {

    $stmt = $conn->prepare("
        INSERT INTO products
        (
            sku,
            product_name,
            description,
            category_id,
            unit,
            image_url,
            minimum_stock,
            maximum_stock,
            status
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE')
    ");

    $stmt->bind_param(
        "sssissii",
        $sku,
        $productName,
        $description,
        $categoryId,
        $unit,
        $imageUrl,
        $minimumStock,
        $maximumStock
    );

    $stmt->execute();

    $productId = $stmt->insert_id;

    $conn->commit();

    responseSuccess([
        "id" => (int)$productId
    ]);
} catch (Exception $e) {

    $conn->rollback();

    if (
        $e instanceof mysqli_sql_exception &&
        $e->getCode() === 1062
    ) {
        responseError("SKU นี้มีอยู่ในระบบแล้ว");
    }

    responseError("ไม่สามารถเพิ่มวัสดุได้");
}
