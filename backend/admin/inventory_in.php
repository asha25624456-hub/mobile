<?php

/**
 * POST /admin/inventory_in.php
 * เพิ่ม Stock
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : product_id, quantity
 */

require_once __DIR__ . '/../bootstrap.php';

$admin = requireAdmin($conn);

$productId = $_POST['product_id'] ?? '';
$quantity = $_POST['quantity'] ?? '';

if (
    !is_numeric($productId) ||
    !is_numeric($quantity) ||
    (int)$productId <= 0 ||
    (int)$quantity <= 0
) {
    responseError("ข้อมูล Stock ไม่ถูกต้อง");
}

$productId = (int)$productId;
$quantity = (int)$quantity;

$conn->begin_transaction();

try {

    $stmt = $conn->prepare("
        SELECT stock_quantity
        FROM products
        WHERE id = ?
        FOR UPDATE
    ");

    $stmt->bind_param("i", $productId);
    $stmt->execute();

    $inventory = $stmt->get_result()->fetch_assoc();

    if (!$inventory) {
        throw new Exception("ไม่พบ Inventory ของวัสดุ");
    }

    $before = (int)$inventory['stock_quantity'];
    $after = $before + $quantity;

    $stmt = $conn->prepare("
        UPDATE products
        SET stock_quantity = ?
        WHERE id = ?
    ");

    $stmt->bind_param(
        "ii",
        $after,
        $productId
    );

    $stmt->execute();

    $type = 'IN';
    $referenceType = 'MANUAL';
    $referenceId = null;

    $stmt = $conn->prepare("
        INSERT INTO inventory_transactions
        (
            product_id,
            transaction_type,
            quantity,
            before_quantity,
            after_quantity,
            reference_type,
            reference_id,
            created_by
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ");

    $stmt->bind_param(
        "isiiisii",
        $productId,
        $type,
        $quantity,
        $before,
        $after,
        $referenceType,
        $referenceId,
        $admin['id']
    );

    $stmt->execute();

    $conn->commit();

    responseSuccess([
        "message" => "เพิ่ม Stock สำเร็จ",
        "quantity" => $after
    ]);
} catch (Exception $e) {

    $conn->rollback();
    responseError(safeMessage($e));
}
