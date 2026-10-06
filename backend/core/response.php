<?php

/**
 * ฟังก์ชันตอบกลับ JSON ของทุก Endpoint
 */

function responseSuccess($data = [])
{
    echo json_encode(
        array_merge(["status" => "success"], $data),
        JSON_UNESCAPED_UNICODE
    );
    exit;
}

function responseError($message)
{
    echo json_encode([
        "status" => "error",
        "message" => $message
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

function safeMessage($e)
{
    if ($e instanceof mysqli_sql_exception) {
        error_log("[project.php] " . $e->getMessage());
        return "เกิดข้อผิดพลาดของฐานข้อมูล กรุณาลองใหม่อีกครั้ง";
    }

    return $e->getMessage();
}
