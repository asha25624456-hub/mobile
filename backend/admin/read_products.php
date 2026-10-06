<?php

/**
 * POST /admin/read_products.php
 * รายการวัสดุทั้งหมด (ทุกสถานะ) พร้อมจำนวนคงเหลือ ค้นหาด้วย search ได้
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : search
 */

require_once __DIR__ . '/../bootstrap.php';

requireAdmin($conn);

$search = trim($_POST['search'] ?? '');

if ($search !== '') {

    $keyword = "%{$search}%";

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
            products.stock_quantity,
            products.reserved_quantity,
            GREATEST(products.stock_quantity - products.reserved_quantity, 0) AS available_quantity
        FROM products
        LEFT JOIN categories
            ON categories.id = products.category_id
        WHERE (
              products.product_name LIKE ?
              OR products.sku LIKE ?
              OR categories.category_name LIKE ?
          )
        ORDER BY products.product_name ASC
    ");

    $stmt->bind_param(
        "sss",
        $keyword,
        $keyword,
        $keyword
    );

    $stmt->execute();

    $result = $stmt->get_result();
} else {

    $result = $conn->query("
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
            products.stock_quantity,
            products.reserved_quantity,
            GREATEST(products.stock_quantity - products.reserved_quantity, 0) AS available_quantity
        FROM products
        LEFT JOIN categories
            ON categories.id = products.category_id
        ORDER BY products.product_name ASC
    ");
}

$products = [];

while ($row = $result->fetch_assoc()) {
    $products[] = $row;
}

responseSuccess([
    "data" => $products
]);
