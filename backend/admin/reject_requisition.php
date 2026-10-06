<?php

/**
 * POST /admin/reject_requisition.php
 * ปฏิเสธทั้งใบเบิก (PENDING → REJECTED)
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : id, comment
 */

require_once __DIR__ . '/../bootstrap.php';

$admin = requireAdmin($conn);

$id = $_POST['id'] ?? '';
$comment = trim($_POST['comment'] ?? '');

if ($id === '' || !is_numeric($id)) {
    responseError("Invalid Requisition ID");
}

$id = (int)$id;

$conn->begin_transaction();

try {

    $stmt = $conn->prepare("
        SELECT
            id,
            requester_id,
            status
        FROM requisitions
        WHERE id = ?
        FOR UPDATE
    ");

    $stmt->bind_param("i", $id);
    $stmt->execute();

    $request = $stmt->get_result()->fetch_assoc();

    if (!$request) {
        throw new Exception("ไม่พบใบเบิก");
    }

    if ($request['status'] !== 'PENDING') {
        throw new Exception("ไม่สามารถปฏิเสธใบเบิกนี้ได้");
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
        SET status = 'REJECTED'
        WHERE id = ?
    ");

    $stmt->bind_param("i", $id);
    $stmt->execute();

    $stmt = $conn->prepare("
        UPDATE requisition_items
        SET
            approved_quantity = 0,
            status = 'REJECTED'
        WHERE requisition_id = ?
    ");

    $stmt->bind_param("i", $id);
    $stmt->execute();

    createStatusLog(
        $conn,
        $id,
        'PENDING',
        'REJECTED',
        null,
        $admin['id'],
        $comment
    );

    createNotification(
        $conn,
        $request['requester_id'],
        null,
        'ใบเบิกถูกปฏิเสธ',
        $comment !== ''
            ? $comment
            : 'ใบเบิกของคุณถูกปฏิเสธ',
        'REQUISITION',
        'REQUISITION',
        $id
    );

    $conn->commit();

    responseSuccess([
        "message" => "ปฏิเสธใบเบิกสำเร็จ"
    ]);
} catch (Exception $e) {

    $conn->rollback();
    responseError(safeMessage($e));
}
