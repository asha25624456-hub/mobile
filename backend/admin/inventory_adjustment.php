<?php

/**
 * POST /admin/inventory_adjustment.php
 * ปรับ Stock ให้เป็นจำนวนที่กำหนด
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
    (int)$quantity < 0
) {
    responseError("จำนวน Stock ไม่ถูกต้อง");
}

$productId = (int)$productId;
$quantity = (int)$quantity;

$conn->begin_transaction();

try {

    $stmt = $conn->prepare("
        SELECT stock_quantity, reserved_quantity
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
    $after = $quantity;

    if ($after < (int)$inventory['reserved_quantity']) {
        throw new Exception("จำนวนสต็อกใหม่ต่ำกว่ายอดที่ถูกจองไว้ไม่ได้");
    }

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

    $type = 'ADJUSTMENT';
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

    $transactionQuantity = abs($after - $before);

    if ($transactionQuantity === 0) {
        $transactionQuantity = 1;
    }

    $stmt->bind_param(
        "isiiisii",
        $productId,
        $type,
        $transactionQuantity,
        $before,
        $after,
        $referenceType,
        $referenceId,
        $admin['id']
    );

    $stmt->execute();

    $conn->commit();

    responseSuccess([
        "message" => "ปรับ Stock สำเร็จ",
        "quantity" => $after
    ]);
} catch (Exception $e) {

    $conn->rollback();
    responseError(safeMessage($e));
}
