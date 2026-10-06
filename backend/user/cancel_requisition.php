<?php

/**
 * POST /user/cancel_requisition.php
 * ยกเลิกใบเบิกของตัวเอง (ได้เฉพาะสถานะ PENDING)
 *
 * สิทธิ์   : User (Authorization: Bearer <token>)
 * รับค่า   : id
 */

require_once __DIR__ . '/../bootstrap.php';

$user = requireUser($conn);

$id = $_POST['id'] ?? '';

if ($id === '' || !is_numeric($id)) {
    responseError("Invalid Requisition ID");
}

$id = (int)$id;

$conn->begin_transaction();

try {

    $stmt = $conn->prepare("
        SELECT id, status
        FROM requisitions
        WHERE id = ?
          AND requester_id = ?
        FOR UPDATE
    ");

    $stmt->bind_param(
        "ii",
        $id,
        $user['id']
    );

    $stmt->execute();

    $request = $stmt->get_result()->fetch_assoc();

    if (!$request) {
        throw new Exception("ไม่พบใบเบิก");
    }

    if (!in_array(
        $request['status'],
        ['PENDING'],
        true
    )) {
        throw new Exception("ไม่สามารถยกเลิกใบเบิกสถานะนี้ได้");
    }

    $stmt = $conn->prepare("
        SELECT product_id, SUM(requested_quantity) AS reserved_quantity
        FROM requisition_items
        WHERE requisition_id = ?
        GROUP BY product_id
        ORDER BY product_id ASC
    ");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $reservedItems = $stmt->get_result();

    while ($reservedItem = $reservedItems->fetch_assoc()) {
        $productId = (int)$reservedItem['product_id'];
        $quantity = (int)$reservedItem['reserved_quantity'];
        $stmt = $conn->prepare("
            UPDATE products
            SET reserved_quantity = reserved_quantity - ?
            WHERE id = ? AND reserved_quantity >= ?
        ");
        $stmt->bind_param("iii", $quantity, $productId, $quantity);
        $stmt->execute();
        if ($stmt->affected_rows !== 1) {
            throw new Exception("คืนยอดจองวัสดุไม่สำเร็จ กรุณาตรวจสอบสต็อก");
        }
    }

    $stmt = $conn->prepare("
        UPDATE requisitions
        SET status = 'CANCELLED'
        WHERE id = ?
    ");

    $stmt->bind_param("i", $id);
    $stmt->execute();

    createStatusLog(
        $conn,
        $id,
        $request['status'],
        'CANCELLED',
        $user['id'],
        null,
        'ผู้เบิกยกเลิกใบเบิก'
    );

    $conn->commit();

    responseSuccess([
        "message" => "ยกเลิกใบเบิกสำเร็จ"
    ]);
} catch (Exception $e) {

    $conn->rollback();
    responseError(safeMessage($e));
}
