<?php

/**
 * POST /user/read_product.php
 * รายละเอียดวัสดุ 1 รายการ
 *
 * สิทธิ์   : User (Authorization: Bearer <token>)
 * รับค่า   : id
 */

require_once __DIR__ . '/../bootstrap.php';

requireUser($conn);

$id = $_POST['id'] ?? $_GET['id'] ?? '';

if ($id === '' || !is_numeric($id)) {
    responseError("Invalid Product ID");
}

$id = (int)$id;

$stmt = $conn->prepare("
    SELECT
        products.id,
        products.sku,
        products.product_name,
        products.description,
        products.category_id,
        categories.category_name,
        products.unit,
        products.image_url,
        products.minimum_stock,
        products.maximum_stock,
        products.status,
        GREATEST(products.stock_quantity - products.reserved_quantity, 0) AS stock_quantity
    FROM products
    LEFT JOIN categories
        ON categories.id = products.category_id
    WHERE products.id = ?
    LIMIT 1
");

$stmt->bind_param("i", $id);
$stmt->execute();

$product = $stmt->get_result()->fetch_assoc();

if (!$product) {
    responseError("ไม่พบวัสดุ");
}

responseSuccess([
    "data" => $product
]);
