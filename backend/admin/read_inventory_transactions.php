<?php

/**
 * POST /admin/read_inventory_transactions.php
 * ประวัติการเคลื่อนไหว Stock กรองด้วย product_id ได้
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : product_id
 */

require_once __DIR__ . '/../bootstrap.php';

requireAdmin($conn);

$productId = $_POST['product_id'] ?? '';

if ($productId !== '' && !is_numeric($productId)) {
    responseError("Invalid Product ID");
}

if ($productId !== '') {

    $productId = (int)$productId;

    $stmt = $conn->prepare("
        SELECT
            it.*,
            p.sku,
            p.product_name,
            a.name AS admin_name
        FROM inventory_transactions it
        INNER JOIN products p
            ON p.id = it.product_id
        INNER JOIN admins a
            ON a.id = it.created_by
        WHERE it.product_id = ?
        ORDER BY it.created_at DESC
    ");

    $stmt->bind_param("i", $productId);
    $stmt->execute();

    $result = $stmt->get_result();
} else {

    $result = $conn->query("
        SELECT
            it.*,
            p.sku,
            p.product_name,
            a.name AS admin_name
        FROM inventory_transactions it
        INNER JOIN products p
            ON p.id = it.product_id
        INNER JOIN admins a
            ON a.id = it.created_by
        ORDER BY it.created_at DESC
    ");
}

$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

responseSuccess([
    "data" => $data
]);
