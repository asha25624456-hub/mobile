<?php

/**
 * POST /user/read_products.php
 * รายการวัสดุที่เปิดใช้งาน พร้อมจำนวนคงเหลือ ค้นหาด้วย search ได้
 *
 * สิทธิ์   : User (Authorization: Bearer <token>)
 * รับค่า   : search
 */

require_once __DIR__ . '/../bootstrap.php';

requireUser($conn);

$search = trim(
    $_POST['search']
        ?? $_GET['search']
        ?? ''
);

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
            GREATEST(products.stock_quantity - products.reserved_quantity, 0) AS stock_quantity
        FROM products
        LEFT JOIN categories
            ON categories.id = products.category_id
        WHERE products.status = 'ACTIVE'
          AND (
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
            GREATEST(products.stock_quantity - products.reserved_quantity, 0) AS stock_quantity
        FROM products
        LEFT JOIN categories
            ON categories.id = products.category_id
        WHERE products.status = 'ACTIVE'
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
