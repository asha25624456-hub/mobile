<?php
// Shared API bootstrap. Uses the same database configuration as the Flutter application.
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Authorization, Content-Type');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') { http_response_code(204); exit; }
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
require_once __DIR__ . '/core/response.php';
require_once __DIR__ . '/core/auth.php';
require_once __DIR__ . '/core/helpers.php';
require_once __DIR__ . '/core/database.php';
set_exception_handler(function ($e) {
    http_response_code(500);
    echo json_encode(['status'=>'error','message'=>safeMessage($e)], JSON_UNESCAPED_UNICODE);
    exit;
});
$conn = connectDatabase();
