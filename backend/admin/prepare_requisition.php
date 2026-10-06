<?php

/**
 * POST /admin/prepare_requisition.php
 * เริ่มจัดเตรียมวัสดุ ใบเบิกยังคงสถานะ APPROVED
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : id
 */

require_once __DIR__ . '/../bootstrap.php';

$admin = requireAdmin($conn);

$id = $_POST['id'] ?? '';

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

    if ($request['status'] !== 'APPROVED') {
        throw new Exception("ใบเบิกต้องได้รับการอนุมัติก่อน");
    }

    $stmt = $conn->prepare("
        UPDATE requisition_items
        SET status = 'PICKING'
        WHERE requisition_id = ?
          AND approved_quantity > 0
    ");

    $stmt->bind_param("i", $id);
    $stmt->execute();

    $conn->commit();

    responseSuccess([
        "message" => "เริ่มจัดเตรียมวัสดุสำเร็จ"
    ]);
} catch (Exception $e) {

    $conn->rollback();
    responseError(safeMessage($e));
}
