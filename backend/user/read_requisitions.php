<?php

/**
 * POST /user/read_requisitions.php
 * ใบเบิกของตัวเอง กรองด้วย status ได้
 *
 * สิทธิ์   : User (Authorization: Bearer <token>)
 * รับค่า   : status
 */

require_once __DIR__ . '/../bootstrap.php';

$user = requireUser($conn);

$status = trim($_POST['status'] ?? '');

if ($status !== '') {

    $stmt = $conn->prepare("
        SELECT
            id,
            request_no,
            purpose,
            required_date,
            status,
            total_items,
            total_quantity,
            created_at,
            updated_at,
            (
                SELECT rsl.comment
                FROM requisition_status_logs rsl
                WHERE rsl.requisition_id = requisitions.id
                  AND rsl.to_status IN ('APPROVED', 'REJECTED')
                  AND rsl.comment IS NOT NULL
                  AND rsl.comment <> ''
                ORDER BY rsl.created_at DESC, rsl.id DESC
                LIMIT 1
            ) AS admin_comment
        FROM requisitions
        WHERE requester_id = ?
          AND status = ?
        ORDER BY created_at DESC
    ");

    $stmt->bind_param(
        "is",
        $user['id'],
        $status
    );

    $stmt->execute();

    $result = $stmt->get_result();
} else {

    $stmt = $conn->prepare("
        SELECT
            id,
            request_no,
            purpose,
            required_date,
            status,
            total_items,
            total_quantity,
            created_at,
            updated_at,
            (
                SELECT rsl.comment
                FROM requisition_status_logs rsl
                WHERE rsl.requisition_id = requisitions.id
                  AND rsl.to_status IN ('APPROVED', 'REJECTED')
                  AND rsl.comment IS NOT NULL
                  AND rsl.comment <> ''
                ORDER BY rsl.created_at DESC, rsl.id DESC
                LIMIT 1
            ) AS admin_comment
        FROM requisitions
        WHERE requester_id = ?
        ORDER BY created_at DESC
    ");

    $stmt->bind_param("i", $user['id']);
    $stmt->execute();

    $result = $stmt->get_result();
}

$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

responseSuccess([
    "data" => $data
]);
