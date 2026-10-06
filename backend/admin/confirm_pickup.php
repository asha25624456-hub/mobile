<?php

/**
 * POST /admin/confirm_pickup.php
 * ยืนยันว่าผู้ใช้รับวัสดุแล้ว (APPROVED → ISSUED) ส่ง pickup_code หรือ qr_token อย่างใดอย่างหนึ่ง
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : pickup_code, qr_token
 */

require_once __DIR__ . '/../bootstrap.php';

$admin = requireAdmin($conn);

$pickupCode = trim($_POST['pickup_code'] ?? '');
$qrToken = trim($_POST['qr_token'] ?? '');

if ($pickupCode === '' && $qrToken === '') {
    responseError("กรุณาระบุ Pickup Code หรือ QR Token");
}

$conn->begin_transaction();

try {

    if ($qrToken !== '') {

        $stmt = $conn->prepare("
            SELECT
                p.*,
                r.requester_id,
                r.status AS requisition_status
            FROM pickups p
            INNER JOIN requisitions r
                ON r.id = p.requisition_id
            WHERE p.qr_token = ?
            FOR UPDATE
        ");

        $stmt->bind_param("s", $qrToken);
    } else {

        $stmt = $conn->prepare("
            SELECT
                p.*,
                r.requester_id,
                r.status AS requisition_status
            FROM pickups p
            INNER JOIN requisitions r
                ON r.id = p.requisition_id
            WHERE p.pickup_code = ?
            FOR UPDATE
        ");

        $stmt->bind_param("s", $pickupCode);
    }

    $stmt->execute();

    $pickup = $stmt->get_result()->fetch_assoc();

    if (!$pickup) {
        throw new Exception("ไม่พบข้อมูล Pickup");
    }

    if (
        $pickup['status'] !== 'READY' ||
        $pickup['requisition_status'] !== 'APPROVED'
    ) {
        throw new Exception("ใบเบิกนี้ยังไม่พร้อมรับหรือถูกรับไปแล้ว");
    }

    $requisitionId = (int)$pickup['requisition_id'];

    $stmt = $conn->prepare("
        SELECT
            id,
            product_id,
            picked_quantity
        FROM requisition_items
        WHERE requisition_id = ?
        FOR UPDATE
    ");

    $stmt->bind_param("i", $requisitionId);
    $stmt->execute();

    $result = $stmt->get_result();

    $items = [];

    while ($row = $result->fetch_assoc()) {
        $items[] = $row;
    }

    foreach ($items as $item) {

        $quantity = (int)$item['picked_quantity'];

        if ($quantity <= 0) {
            continue;
        }

        $stmt = $conn->prepare("
            UPDATE requisition_items
            SET
                issued_quantity = ?,
                status = 'ISSUED'
            WHERE id = ?
        ");

        $stmt->bind_param(
            "ii",
            $quantity,
            $item['id']
        );

        $stmt->execute();

    }

    $stmt = $conn->prepare("
        UPDATE pickups
        SET
            status = 'PICKED_UP',
            picked_up_at = NOW(),
            confirmed_by = ?
        WHERE id = ?
    ");

    $stmt->bind_param(
        "ii",
        $admin['id'],
        $pickup['id']
    );

    $stmt->execute();

    $stmt = $conn->prepare("
        UPDATE requisitions
        SET status = 'ISSUED'
        WHERE id = ?
    ");

    $stmt->bind_param("i", $requisitionId);
    $stmt->execute();

    createStatusLog(
        $conn,
        $requisitionId,
        'APPROVED',
        'ISSUED',
        null,
        $admin['id'],
        'ยืนยันการรับวัสดุและตัด Stock'
    );

    createNotification(
        $conn,
        $pickup['requester_id'],
        null,
        'รับวัสดุสำเร็จ',
        'ใบเบิกของคุณดำเนินการเสร็จสมบูรณ์แล้ว',
        'REQUISITION',
        'REQUISITION',
        $requisitionId
    );

    $conn->commit();

    responseSuccess([
        "message" => "ยืนยันการรับวัสดุสำเร็จ"
    ]);
} catch (Exception $e) {

    $conn->rollback();
    responseError(safeMessage($e));
}
