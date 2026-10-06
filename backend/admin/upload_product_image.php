<?php

/**
 * POST /admin/upload_product_image.php
 * Upload an image for a product and save its public path in products.image_url.
 */

require_once __DIR__ . '/../bootstrap.php';

requireAdmin($conn);

$productId = $_POST['product_id'] ?? '';
if ($productId === '' || !ctype_digit((string)$productId) || (int)$productId < 1) {
    responseError('Invalid Product ID');
}

if (!isset($_FILES['image']) || !is_uploaded_file($_FILES['image']['tmp_name'])) {
    responseError('Please choose an image');
}

$image = $_FILES['image'];
if (($image['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
    responseError('Image upload failed');
}

if (($image['size'] ?? 0) > 5 * 1024 * 1024) {
    responseError('Image must be 5 MB or smaller');
}

$mime = (new finfo(FILEINFO_MIME_TYPE))->file($image['tmp_name']);
$extensions = [
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'image/webp' => 'webp',
];

if (!isset($extensions[$mime]) || @getimagesize($image['tmp_name']) === false) {
    responseError('Use a valid JPG, PNG, or WebP image');
}

$productId = (int)$productId;
$check = $conn->prepare('SELECT id FROM products WHERE id = ? LIMIT 1');
$check->bind_param('i', $productId);
$check->execute();
if (!$check->get_result()->fetch_assoc()) {
    responseError('Product not found');
}

$directory = __DIR__ . '/../uploads/products';
if (!is_dir($directory) && !mkdir($directory, 0755, true) && !is_dir($directory)) {
    responseError('Image storage is not available on the server');
}

$filename = bin2hex(random_bytes(16)) . '.' . $extensions[$mime];
$destination = $directory . '/' . $filename;
if (!move_uploaded_file($image['tmp_name'], $destination)) {
    responseError('Could not save the image on the server');
}

$scriptPath = str_replace('\\', '/', $_SERVER['SCRIPT_NAME'] ?? '/backend/admin/upload_product_image.php');
$backendPath = dirname(dirname($scriptPath));
$imageUrl = rtrim($backendPath, '/') . '/uploads/products/' . $filename;

try {
    $update = $conn->prepare('UPDATE products SET image_url = ? WHERE id = ?');
    $update->bind_param('si', $imageUrl, $productId);
    $update->execute();
} catch (Throwable $error) {
    @unlink($destination);
    throw $error;
}

responseSuccess(['image_url' => $imageUrl]);
