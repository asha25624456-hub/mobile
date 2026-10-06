<?php

/**
 * เชื่อมต่อฐานข้อมูลตามค่าใน config.php
 */

function connectDatabase()
{
    $config = require __DIR__ . '/../config.php';

    try {
        $conn = new mysqli(
            $config['host'],
            $config['user'],
            $config['pass'],
            $config['name']
        );

        $conn->set_charset("utf8mb4");

        return $conn;

    } catch (Exception $e) {
        echo json_encode([
            "status" => "error",
            "message" => "Database connection failed"
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
}
