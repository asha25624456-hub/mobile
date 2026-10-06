<?php

/**
 * POST /user/read_requisition.php
 * รายละเอียดใบเบิกของตัวเอง พร้อมรายการวัสดุ
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

$stmt = $conn->prepare("
    SELECT
        r.id,
        r.request_no,
        r.purpose,
        r.required_date,
        r.status,
        r.total_items,
        r.total_quantity,
        r.created_at,
        r.updated_at,
        (
            SELECT rsl.comment
            FROM requisition_status_logs rsl
            WHERE rsl.requisition_id = r.id
              AND rsl.to_status IN ('APPROVED', 'REJECTED')
              AND rsl.comment IS NOT NULL
              AND rsl.comment <> ''
            ORDER BY rsl.created_at DESC, rsl.id DESC
            LIMIT 1
        ) AS admin_comment
    FROM requisitions r
    WHERE r.id = ?
      AND r.requester_id = ?
    LIMIT 1
");

$stmt->bind_param(
    "ii",
    $id,
    $user['id']
);

$stmt->execute();

$requisition = $stmt->get_result()->fetch_assoc();

if (!$requisition) {
    responseError("ไม่พบใบเบิก");
}

$stmt = $conn->prepare("
    SELECT
        ri.id,
        ri.product_id,
        p.sku,
        p.product_name,
        ri.requested_quantity,
        ri.approved_quantity,
        ri.picked_quantity,
        ri.issued_quantity,
        ri.unit,
        ri.status
    FROM requisition_items ri
    INNER JOIN products p
        ON p.id = ri.product_id
    WHERE ri.requisition_id = ?
    ORDER BY ri.id ASC
");

$stmt->bind_param("i", $id);
$stmt->execute();

$items = [];

$result = $stmt->get_result();

while ($row = $result->fetch_assoc()) {
    $items[] = $row;
}

$requisition['items'] = $items;

responseSuccess([
    "data" => $requisition
]);
