<?php

/**
 * เครื่องมือสร้างบัญชี "ผู้ดูแลระบบ (Admin)" คนแรก
 *
 * ใช้ครั้งเดียวตอนเริ่มระบบ เพราะปกติ auth/register_user.php มีให้แค่ฝั่งผู้เบิกวัสดุ
 * ฝั่ง Admin ไม่มีการสมัครเอง เพื่อไม่ให้ใครก็เข้ามาสมัครเป็นผู้ดูแลระบบได้
 *
 * ความปลอดภัย: หน้านี้จะ "ใช้ได้เฉพาะตอนที่ตาราง admins ยังว่างอยู่เท่านั้น"
 * พอสร้างผู้ดูแลระบบคนแรกสำเร็จแล้ว หน้านี้จะปิดตัวเองอัตโนมัติทันที
 * (เพิ่มผู้ดูแลระบบคนถัดไปให้ทำผ่านหน้าเว็บ Admin แทน หลังจากล็อกอินด้วยบัญชีแรกนี้ได้แล้ว)
 *
 * แนะนำ: ลบไฟล์นี้ทิ้งจาก Server หลังสร้างบัญชีแรกเสร็จ เพื่อความปลอดภัยสูงสุด
 */

require_once __DIR__ . '/../core/database.php';

$conn = connectDatabase();

$existingCount = (int)$conn->query("SELECT COUNT(*) AS c FROM admins")
    ->fetch_assoc()['c'];

$message = '';
$success = false;

if ($existingCount === 0 && ($_SERVER['REQUEST_METHOD'] ?? '') === 'POST') {

    $username = trim($_POST['username'] ?? '');
    $name = trim($_POST['name'] ?? '');
    $email = strtolower(trim($_POST['email'] ?? ''));
    $password = $_POST['password'] ?? '';
    $confirm = $_POST['confirm'] ?? '';

    if ($username === '' || $name === '' || $email === '' || $password === '') {
        $message = 'กรุณากรอกข้อมูลให้ครบถ้วน';
    } elseif (mb_strlen($username) > 100) {
        $message = 'Username ต้องไม่เกิน 100 ตัวอักษร';
    } elseif (mb_strlen($name) > 150) {
        $message = 'ชื่อต้องไม่เกิน 150 ตัวอักษร';
    } elseif (strlen($email) > 150 || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $message = 'รูปแบบอีเมลไม่ถูกต้อง';
    } elseif (strlen($password) < 8) {
        $message = 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
    } elseif (strlen($password) > 72) {
        $message = 'รหัสผ่านต้องไม่เกิน 72 ตัวอักษร';
    } elseif ($password !== $confirm) {
        $message = 'รหัสผ่านและยืนยันรหัสผ่านไม่ตรงกัน';
    } else {

        // กันแข่งกันสร้างซ้ำ (race condition) ตรวจจำนวนอีกครั้งตอนจะ insert จริง
        $conn->begin_transaction();

        try {
            $recheck = (int)$conn->query("SELECT COUNT(*) AS c FROM admins FOR UPDATE")
                ->fetch_assoc()['c'];

            if ($recheck > 0) {
                throw new Exception('มีผู้ดูแลระบบอยู่แล้ว ไม่สามารถสร้างซ้ำได้');
            }

            $passwordHash = password_hash($password, PASSWORD_DEFAULT);

            $stmt = $conn->prepare("
                INSERT INTO admins
                (
                    username,
                    name,
                    email,
                    password_hash
                )
                VALUES (?, ?, ?, ?)
            ");

            $stmt->bind_param(
                "ssss",
                $username,
                $name,
                $email,
                $passwordHash
            );

            $stmt->execute();

            $conn->commit();

            $success = true;
            $existingCount = 1;
        } catch (Exception $e) {

            $conn->rollback();

            if ($e instanceof mysqli_sql_exception && $e->getCode() === 1062) {
                $message = 'Username หรืออีเมลนี้ถูกใช้งานแล้ว';
            } else {
                $message = $e->getMessage();
            }
        }
    }
}

?>
<!DOCTYPE html>
<html lang="th">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>สร้างบัญชีผู้ดูแลระบบ</title>
<style>
  :root { --ink:#14213D; --paper:#F7F4EC; --line:#E1DDD0; --err:#B3261E; --errbg:#FDECEA; --ok:#1E8449; --okbg:#E1F5E9; }
  * { box-sizing: border-box; }
  body { margin:0; background:var(--paper); font-family: -apple-system, "Segoe UI", "Sarabun", sans-serif; color:var(--ink); }
  .wrap { max-width: 420px; margin: 48px auto; padding: 0 20px; }
  .card { background:#fff; border:1px solid var(--line); border-radius:14px; padding:28px; }
  h1 { font-size: 22px; margin: 0 0 6px; }
  p.sub { color:#5B6577; margin: 0 0 22px; font-size: 14px; line-height:1.5; }
  label { display:block; font-weight:700; font-size: 13px; margin: 14px 0 6px; }
  input { width:100%; padding: 11px 12px; border-radius:8px; border:1px solid var(--line); font-size:14px; }
  input:focus { outline:2px solid var(--ink); outline-offset: -1px; }
  button { width:100%; margin-top:20px; padding:13px; border:none; border-radius:8px; background:var(--ink); color:#fff; font-weight:700; font-size:15px; cursor:pointer; }
  .msg { padding:12px 14px; border-radius:8px; font-size:13.5px; line-height:1.5; margin-bottom: 6px; }
  .msg.err { background:var(--errbg); color:var(--err); }
  .msg.ok { background:var(--okbg); color:var(--ok); }
  .tag { display:inline-block; background:#FFC300; color:var(--ink); font-weight:800; font-size:12px; padding:5px 10px; border-radius:6px; margin-bottom:14px; }
</style>
</head>
<body>
  <div class="wrap">
    <div class="tag">SmartRequisition · Setup</div>
    <div class="card">
      <?php if ($success): ?>
        <h1>สร้างบัญชีผู้ดูแลระบบสำเร็จ</h1>
        <div class="msg ok">
          สร้างบัญชี Admin คนแรกเรียบร้อยแล้ว นำ Username และรหัสผ่านที่ตั้งไว้ไปเข้าสู่ระบบได้เลย
          <br><br>
          <strong>สำคัญ:</strong> กรุณาลบไฟล์นี้ (<code>backend/tools/create_admin.php</code>)
          ออกจาก Server ตอนนี้เลย เพื่อความปลอดภัย หน้านี้จะไม่แสดงฟอร์มอีกต่อไปแล้ว
          แต่ไฟล์ยังอยู่บน Server จนกว่าจะลบเอง
        </div>
      <?php elseif ($existingCount > 0): ?>
        <h1>ปิดใช้งานแล้ว</h1>
        <div class="msg err">
          มีบัญชีผู้ดูแลระบบอยู่แล้วในระบบ หน้านี้ใช้สร้างได้เฉพาะบัญชีแรกเท่านั้น
          ถ้าต้องการเพิ่มผู้ดูแลระบบคนถัดไป ให้ทำผ่านหน้าเว็บ Admin หลังล็อกอินแล้ว
        </div>
      <?php else: ?>
        <h1>สร้างบัญชีผู้ดูแลระบบคนแรก</h1>
        <p class="sub">ใช้ครั้งเดียวตอนเริ่มระบบ หลังสร้างเสร็จหน้านี้จะปิดตัวเองอัตโนมัติ</p>

        <?php if ($message !== ''): ?>
          <div class="msg err"><?= htmlspecialchars($message, ENT_QUOTES, 'UTF-8') ?></div>
        <?php endif; ?>

        <form method="POST">
          <label>Username</label>
          <input type="text" name="username" required maxlength="100"
                 value="<?= htmlspecialchars($_POST['username'] ?? '', ENT_QUOTES, 'UTF-8') ?>">

          <label>ชื่อ-นามสกุล</label>
          <input type="text" name="name" required maxlength="150"
                 value="<?= htmlspecialchars($_POST['name'] ?? '', ENT_QUOTES, 'UTF-8') ?>">

          <label>อีเมล</label>
          <input type="email" name="email" required maxlength="150"
                 value="<?= htmlspecialchars($_POST['email'] ?? '', ENT_QUOTES, 'UTF-8') ?>">

          <label>รหัสผ่าน (อย่างน้อย 8 ตัวอักษร)</label>
          <input type="password" name="password" required minlength="8" maxlength="72">

          <label>ยืนยันรหัสผ่าน</label>
          <input type="password" name="confirm" required minlength="8" maxlength="72">

          <button type="submit">สร้างบัญชีผู้ดูแลระบบ</button>
        </form>
      <?php endif; ?>
    </div>
  </div>
</body>
</html>
