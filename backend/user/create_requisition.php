<?php

/**
 * POST /user/create_requisition.php
 * สร้างใบเบิกวัสดุ (สถานะเริ่มต้น PENDING)
 *
 * สิทธิ์   : User (Authorization: Bearer <token>)
 * รับค่า   : purpose, required_date, items
 * หมายเหตุ : items = JSON เช่น [{"product_id":1,"quantity":3}] วัสดุซ้ำกันจะถูกรวมจำนวนให้
 */

require_once __DIR__ . '/../bootstrap.php';

$user = requireUser($conn);

$purpose = trim($_POST['purpose'] ?? '');
$requiredDate = trim($_POST['required_date'] ?? '');
$itemsJson = $_POST['items'] ?? '';

if ($itemsJson === '') {
    responseError("กรุณาเลือกรายการวัสดุ");
}

$items = json_decode($itemsJson, true);

if (!is_array($items) || count($items) === 0) {
    responseError("รายการวัสดุไม่ถูกต้อง");
}

$mergedItems = [];

foreach ($items as $item) {

    $pid = $item['product_id'] ?? 0;
    $qty = $item['quantity'] ?? 0;

    if (
        !is_numeric($pid) ||
        !is_numeric($qty) ||
        (int)$pid <= 0 ||
        (int)$qty <= 0
    ) {
        responseError("รายการวัสดุไม่ถูกต้อง");
    }

    $pid = (int)$pid;

    $mergedItems[$pid] = ($mergedItems[$pid] ?? 0) + (int)$qty;
}

$items = [];

foreach ($mergedItems as $pid => $qty) {
    $items[] = [
        "product_id" => $pid,
        "quantity" => $qty
    ];
}

usort($items, function ($a, $b) {
    return $a['product_id'] <=> $b['product_id'];
});

$conn->begin_transaction();

try {

    $requestNo = generateRequestNo();

    $stmt = $conn->prepare("
        INSERT INTO requisitions
        (
            request_no,
            requester_id,
            purpose,
            required_date,
            status
        )
        VALUES (?, ?, ?, NULLIF(?, ''), 'PENDING')
    ");

    $stmt->bind_param(
        "siss",
        $requestNo,
        $user['id'],
        $purpose,
        $requiredDate
    );

    $stmt->execute();

    $requisitionId = $stmt->insert_id;

    $totalItems = 0;
    $totalQuantity = 0;

    foreach ($items as $item) {

        $productId = $item['product_id'] ?? 0;
        $quantity = $item['quantity'] ?? 0;

        if (
            !is_numeric($productId) ||
            !is_numeric($quantity) ||
            (int)$productId <= 0 ||
            (int)$quantity <= 0
        ) {
            throw new Exception("รายการวัสดุไม่ถูกต้อง");
        }

        $productId = (int)$productId;
        $quantity = (int)$quantity;

        $stmt = $conn->prepare("
            SELECT
                id,
                unit,
                status,
                stock_quantity,
                reserved_quantity
            FROM products
            WHERE id = ?
            FOR UPDATE
        ");

        $stmt->bind_param("i", $productId);
        $stmt->execute();

        $product = $stmt->get_result()->fetch_assoc();

        if (!$product || $product['status'] !== 'ACTIVE') {
            throw new Exception("ไม่พบวัสดุที่เลือก");
        }

        $availableQuantity = max(
            0,
            (int)$product['stock_quantity'] - (int)$product['reserved_quantity']
        );
        if ($quantity > $availableQuantity) {
            throw new Exception("วัสดุคงเหลือไม่พอ จำนวนที่จองได้คือ {$availableQuantity}");
        }

        $stmt = $conn->prepare("
            UPDATE products
            SET reserved_quantity = reserved_quantity + ?
            WHERE id = ?
        ");
        $stmt->bind_param("ii", $quantity, $productId);
        $stmt->execute();

        $stmt = $conn->prepare("
            INSERT INTO requisition_items
            (
                requisition_id,
                product_id,
                requested_quantity,
                unit,
                status
            )
            VALUES (?, ?, ?, ?, 'PENDING')
        ");

        $stmt->bind_param(
            "iiis",
            $requisitionId,
            $productId,
            $quantity,
            $product['unit']
        );

        $stmt->execute();

        $totalItems++;
        $totalQuantity += $quantity;
    }

    $stmt = $conn->prepare("
        UPDATE requisitions
        SET
            total_items = ?,
            total_quantity = ?
        WHERE id = ?
    ");

    $stmt->bind_param(
        "iii",
        $totalItems,
        $totalQuantity,
        $requisitionId
    );

    $stmt->execute();

    createStatusLog(
        $conn,
        $requisitionId,
        null,
        'PENDING',
        $user['id'],
        null,
        'สร้างใบเบิก'
    );

    // แจ้งเตือนผู้ดูแลระบบทุกคนที่เปิดใช้งานอยู่ ว่ามีใบเบิกใหม่รออนุมัติ
    $adminResult = $conn->query("
        SELECT id
        FROM admins
        WHERE account_status = 'ACTIVE'
    ");

    while ($adminRow = $adminResult->fetch_assoc()) {

        createNotification(
            $conn,
            null,
            (int)$adminRow['id'],
            'มีใบเบิกใหม่รออนุมัติ',
            "ใบเบิก {$requestNo} รออนุมัติ ({$totalItems} รายการ, {$totalQuantity} ชิ้น)",
            'REQUISITION',
            'REQUISITION',
            $requisitionId
        );
    }

    $conn->commit();

    responseSuccess([
        "id" => (int)$requisitionId,
        "request_no" => $requestNo
    ]);
} catch (Exception $e) {

    $conn->rollback();
    responseError(safeMessage($e));
}
