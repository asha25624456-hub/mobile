<?php

/**
 * ฟังก์ชันช่วยที่หลาย Endpoint ใช้ร่วมกัน
 * (สร้างเลขที่ใบเบิก / รหัสรับวัสดุ / แจ้งเตือน / บันทึกสถานะ)
 */

function generateRequestNo()
{
    return 'REQ-' . date('YmdHis') . '-' . strtoupper(bin2hex(random_bytes(2)));
}

function generatePickupCode()
{
    return 'PK-' . date('YmdHis') . '-' . strtoupper(bin2hex(random_bytes(2)));
}

function generateQrToken()
{
    return bin2hex(random_bytes(32));
}

function createNotification(
    $conn,
    $userId,
    $adminId,
    $title,
    $message,
    $type = null,
    $referenceType = null,
    $referenceId = null
) {
    $stmt = $conn->prepare("
        INSERT INTO notifications
        (
            user_id,
            admin_id,
            title,
            message,
            type,
            reference_type,
            reference_id
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ");

    $stmt->bind_param(
        "iissssi",
        $userId,
        $adminId,
        $title,
        $message,
        $type,
        $referenceType,
        $referenceId
    );

    $stmt->execute();
}

function createStatusLog(
    $conn,
    $requisitionId,
    $fromStatus,
    $toStatus,
    $userId = null,
    $adminId = null,
    $comment = null
) {
    $stmt = $conn->prepare("
        INSERT INTO requisition_status_logs
        (
            requisition_id,
            from_status,
            to_status,
            changed_by_user,
            changed_by_admin,
            comment
        )
        VALUES (?, ?, ?, ?, ?, ?)
    ");

    $stmt->bind_param(
        "issiis",
        $requisitionId,
        $fromStatus,
        $toStatus,
        $userId,
        $adminId,
        $comment
    );

    $stmt->execute();
}
