<?php

/**
 * POST /admin/ready_requisition.php
 * เตรียมเสร็จ สร้างรหัส / QR รับวัสดุ ใบเบิกยังคงสถานะ APPROVED
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
        throw new Exception("ใบเบิกต้องได้รับอนุมัติก่อนจึงจะพร้อมรับได้");
    }

    $stmt = $conn->prepare("
        UPDATE requisition_items
        SET
            picked_quantity = approved_quantity,
            status = 'PICKED'
        WHERE requisition_id = ?
          AND approved_quantity > 0
    ");

    $stmt->bind_param("i", $id);
    $stmt->execute();

    $stmt = $conn->prepare("
        SELECT id
        FROM pickups
        WHERE requisition_id = ?
        LIMIT 1
    ");

    $stmt->bind_param("i", $id);
    $stmt->execute();

    $pickup = $stmt->get_result()->fetch_assoc();

    if (!$pickup) {

        $pickupCode = generatePickupCode();
        $qrToken = generateQrToken();

        $stmt = $conn->prepare("
            INSERT INTO pickups
            (
                requisition_id,
                pickup_code,
                qr_token,
                status,
                prepared_at
            )
            VALUES (?, ?, ?, 'READY', NOW())
        ");

        $stmt->bind_param(
            "iss",
            $id,
            $pickupCode,
            $qrToken
        );

        $stmt->execute();
    } else {

        $stmt = $conn->prepare("
            UPDATE pickups
            SET
                status = 'READY',
                prepared_at = NOW()
            WHERE requisition_id = ?
        ");

        $stmt->bind_param("i", $id);
        $stmt->execute();
    }
    createNotification(
        $conn,
        $request['requester_id'],
        null,
        'วัสดุพร้อมรับ',
        'ใบเบิกของคุณเตรียมเสร็จแล้ว สามารถมารับวัสดุได้',
        'PICKUP',
        'REQUISITION',
        $id
    );

    $conn->commit();

    responseSuccess([
        "message" => "เตรียมวัสดุเสร็จแล้ว"
    ]);
} catch (Exception $e) {

    $conn->rollback();
    responseError(safeMessage($e));
}
