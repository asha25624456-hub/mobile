<?php

/**
 * POST /ping.php
 * ตรวจว่า API และฐานข้อมูลทำงานอยู่
 *
 * สิทธิ์   : ไม่ต้องล็อกอิน
 * รับค่า   : -
 */

require_once __DIR__ . '/bootstrap.php';

responseSuccess([
    "message" => "Material Requisition API is running",
    "version" => "2.0.0"
]);
