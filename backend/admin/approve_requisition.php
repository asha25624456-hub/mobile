<?php

/**
 * POST /admin/approve_requisition.php
 * อนุมัติใบเบิก โดยระบุจำนวนที่อนุมัติรายรายการ (PENDING → APPROVED / REJECTED)
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : id, items
 * หมายเหตุ : items = JSON เช่น [{"item_id":11,"approved_quantity":3}] รายการที่ไม่ส่งมาจะถูกปฏิเสธ
 */

require_once __DIR__ . '/../bootstrap.php';

$admin = requireAdmin($conn);

$id = $_POST['id'] ?? '';
$itemsJson = $_POST['items'] ?? '';

if ($id === '' || !is_numeric($id)) {
    responseError("Invalid Requisition ID");
}

$id = (int)$id;

if ($itemsJson === '') {
    responseError("กรุณาระบุจำนวนที่อนุมัติ");
}

$items = json_decode($itemsJson, true);

if (!is_array($items)) {
    responseError("ข้อมูลจำนวนอนุมัติไม่ถูกต้อง");
}

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
        throw new Exception("ใบเบิกนี้ไม่อยู่ในสถานะรออนุมัติ");
    }

    $approvedTotal = 0;

    foreach ($items as $item) {

        $itemId = $item['item_id'] ?? 0;
        $approved = $item['approved_quantity'] ?? 0;

        if (
            !is_numeric($itemId) ||
            !is_numeric($approved)
        ) {
            throw new Exception("ข้อมูลรายการอนุมัติไม่ถูกต้อง");
        }

        $itemId = (int)$itemId;
        $approved = (int)$approved;

        $stmt = $conn->prepare("
            SELECT
                id,
                requested_quantity
            FROM requisition_items
            WHERE id = ?
              AND requisition_id = ?
            FOR UPDATE
        ");

        $stmt->bind_param(
            "ii",
            $itemId,
            $id
        );

        $stmt->execute();

        $row = $stmt->get_result()->fetch_assoc();

        if (!$row) {
            throw new Exception("ไม่พบรายการวัสดุ");
        }

        if (
            $approved < 0 ||
            $approved > (int)$row['requested_quantity']
        ) {
            throw new Exception("จำนวนอนุมัติไม่ถูกต้อง");
        }

        $itemStatus = $approved > 0
            ? 'APPROVED'
            : 'REJECTED';

        $stmt = $conn->prepare("
            UPDATE requisition_items
            SET
                approved_quantity = ?,
                status = ?
            WHERE id = ?
        ");

        $stmt->bind_param(
            "isi",
            $approved,
            $itemStatus,
            $itemId
        );

        $stmt->execute();

        $approvedTotal += $approved;
    }

    $stmt = $conn->prepare("
        UPDATE requisition_items
        SET
            approved_quantity = 0,
            status = 'REJECTED'
        WHERE requisition_id = ?
          AND status = 'PENDING'
    ");

    $stmt->bind_param("i", $id);
    $stmt->execute();

    $stmt = $conn->prepare("
        SELECT
            COALESCE(SUM(approved_quantity), 0) AS total_approved
        FROM requisition_items
        WHERE requisition_id = ?
    ");

    $stmt->bind_param("i", $id);
    $stmt->execute();

    $totalApproved = (int)$stmt
        ->get_result()
        ->fetch_assoc()['total_approved'];

    $stmt = $conn->prepare("
        SELECT
            product_id,
            SUM(requested_quantity) AS requested_quantity,
            SUM(approved_quantity) AS approved_quantity
        FROM requisition_items
        WHERE requisition_id = ?
        GROUP BY product_id
        ORDER BY product_id ASC
    ");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $stockItems = $stmt->get_result();

    while ($stockItem = $stockItems->fetch_assoc()) {
        $productId = (int)$stockItem['product_id'];
        $requestedQuantity = (int)$stockItem['requested_quantity'];
        $approvedQuantity = (int)$stockItem['approved_quantity'];

        $stmt = $conn->prepare("
            SELECT stock_quantity, reserved_quantity
            FROM products
            WHERE id = ?
            FOR UPDATE
        ");
        $stmt->bind_param("i", $productId);
        $stmt->execute();
        $productStock = $stmt->get_result()->fetch_assoc();

        if (
            !$productStock ||
            (int)$productStock['stock_quantity'] < $approvedQuantity ||
            (int)$productStock['reserved_quantity'] < $requestedQuantity
        ) {
            throw new Exception("ยอดสต็อกหรือยอดจองไม่ตรงกับใบเบิก กรุณาตรวจสอบสต็อกก่อนอนุมัติ");
        }

        $beforeQuantity = (int)$productStock['stock_quantity'];
        $afterQuantity = $beforeQuantity - $approvedQuantity;

        $stmt = $conn->prepare("
            UPDATE products
            SET
                stock_quantity = stock_quantity - ?,
                reserved_quantity = reserved_quantity - ?
            WHERE id = ?
              AND stock_quantity >= ?
              AND reserved_quantity >= ?
        ");
        $stmt->bind_param(
            "iiiii",
            $approvedQuantity,
            $requestedQuantity,
            $productId,
            $approvedQuantity,
            $requestedQuantity
        );
        $stmt->execute();

        if ($stmt->affected_rows !== 1) {
            throw new Exception("ปรับสต็อกไม่สำเร็จ กรุณาลองใหม่");
        }

        if ($approvedQuantity > 0) {
            $transactionType = 'OUT';
            $referenceType = 'REQUISITION';
            $referenceId = $id;

            $stmt = $conn->prepare("
                INSERT INTO inventory_transactions
                (
                    product_id, transaction_type, quantity, before_quantity,
                    after_quantity, reference_type, reference_id, created_by
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->bind_param(
                "isiiisii",
                $productId,
                $transactionType,
                $approvedQuantity,
                $beforeQuantity,
                $afterQuantity,
                $referenceType,
                $referenceId,
                $admin['id']
            );
            $stmt->execute();
        }
    }

    $newStatus = $totalApproved > 0
        ? 'APPROVED'
        : 'REJECTED';

    $stmt = $conn->prepare("
        UPDATE requisitions
        SET
            status = ?,
            total_quantity = ?
        WHERE id = ?
    ");

    $stmt->bind_param(
        "sii",
        $newStatus,
        $totalApproved,
        $id
    );

    $stmt->execute();

    createStatusLog(
        $conn,
        $id,
        'PENDING',
        $newStatus,
        null,
        $admin['id'],
        'Admin อนุมัติใบเบิก'
    );

    createNotification(
        $conn,
        $request['requester_id'],
        null,
        $newStatus === 'APPROVED'
            ? 'ใบเบิกได้รับการอนุมัติ'
            : 'ใบเบิกถูกปฏิเสธ',
        $newStatus === 'APPROVED'
            ? 'ใบเบิกของคุณได้รับการอนุมัติแล้ว'
            : 'ใบเบิกของคุณถูกปฏิเสธ',
        'REQUISITION',
        'REQUISITION',
        $id
    );

    $conn->commit();

    responseSuccess([
        "message" => $newStatus === 'APPROVED'
            ? "อนุมัติใบเบิกสำเร็จ"
            : "ปฏิเสธใบเบิกสำเร็จ",
        "status" => $newStatus
    ]);
} catch (Exception $e) {

    $conn->rollback();
    responseError(safeMessage($e));
}
