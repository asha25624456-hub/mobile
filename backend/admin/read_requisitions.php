<?php

/**
 * POST /admin/read_requisitions.php
 * ใบเบิกทั้งหมด กรองด้วย status ได้
 *
 * สิทธิ์   : Admin (Authorization: Bearer <token>)
 * รับค่า   : status
 */

require_once __DIR__ . '/../bootstrap.php';

requireAdmin($conn);

$status = trim($_POST['status'] ?? '');

if ($status !== '') {

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
            p.status AS pickup_status,
            u.employee_code,
            u.name AS requester_name,
            u.email AS requester_email
        FROM requisitions r
        INNER JOIN users u
            ON u.id = r.requester_id
        LEFT JOIN pickups p
            ON p.requisition_id = r.id
        WHERE r.status = ?
        ORDER BY r.created_at DESC
    ");

    $stmt->bind_param("s", $status);
    $stmt->execute();

    $result = $stmt->get_result();
} else {

    $result = $conn->query("
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
            p.status AS pickup_status,
            u.employee_code,
            u.name AS requester_name,
            u.email AS requester_email
        FROM requisitions r
        INNER JOIN users u
            ON u.id = r.requester_id
        LEFT JOIN pickups p
            ON p.requisition_id = r.id
        ORDER BY r.created_at DESC
    ");
}

$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

responseSuccess([
    "data" => $data
]);
