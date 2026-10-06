<?php

/**
 * POST /admin/update_product.php
 * แก้ไขข้อมูลวัสดุ
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : id, sku, product_name, description, category_id, unit, image_url, minimum_stock, maximum_stock, status
 */

require_once __DIR__ . '/../bootstrap.php';

requireAdmin($conn);

$id = $_POST['id'] ?? '';

if ($id === '' || !is_numeric($id)) {
    responseError("Invalid Product ID");
}

$id = (int)$id;

$sku = trim($_POST['sku'] ?? '');
$productName = trim($_POST['product_name'] ?? '');
$description = trim($_POST['description'] ?? '');
$categoryId = $_POST['category_id'] ?? '';
$unit = trim($_POST['unit'] ?? '');
$imageUrl = trim($_POST['image_url'] ?? '');
$minimumStock = $_POST['minimum_stock'] ?? 0;
$maximumStock = $_POST['maximum_stock'] ?? 0;
$status = $_POST['status'] ?? 'ACTIVE';

if ($sku === '' || $productName === '' || $unit === '') {
    responseError("กรุณากรอกข้อมูลวัสดุให้ครบ");
}

if ($categoryId !== '' && !is_numeric($categoryId)) {
    responseError("Invalid Category ID");
}

if (!in_array($status, ['ACTIVE', 'INACTIVE'], true)) {
    responseError("สถานะไม่ถูกต้อง");
}

if (!is_numeric($minimumStock) || $minimumStock < 0) {
    responseError("Minimum Stock ไม่ถูกต้อง");
}

if (!is_numeric($maximumStock) || $maximumStock < 0) {
    responseError("Maximum Stock ไม่ถูกต้อง");
}

$categoryId = $categoryId === ''
    ? 0
    : (int)$categoryId;

$minimumStock = (int)$minimumStock;
$maximumStock = (int)$maximumStock;

if ($maximumStock > 0 && $maximumStock < $minimumStock) {
    responseError("Maximum Stock ต้องมากกว่าหรือเท่ากับ Minimum Stock");
}

try {

    $stmt = $conn->prepare("
        UPDATE products
        SET
            sku = ?,
            product_name = ?,
            description = ?,
            category_id = NULLIF(?, 0),
            unit = ?,
            image_url = ?,
            minimum_stock = ?,
            maximum_stock = ?,
            status = ?
        WHERE id = ?
    ");

    $stmt->bind_param(
        "sssissiisi",
        $sku,
        $productName,
        $description,
        $categoryId,
        $unit,
        $imageUrl,
        $minimumStock,
        $maximumStock,
        $status,
        $id
    );

    $stmt->execute();

    responseSuccess([
        "message" => "แก้ไขวัสดุสำเร็จ"
    ]);
} catch (Exception $e) {

    if (
        $e instanceof mysqli_sql_exception &&
        $e->getCode() === 1062
    ) {
        responseError("SKU นี้มีอยู่ในระบบแล้ว");
    }

    responseError("ไม่สามารถแก้ไขวัสดุได้");
}
