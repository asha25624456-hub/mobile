# Backend: Material Requisition API

PHP + MySQL แยกเป็นไฟล์ละ 1 Endpoint ทุกไฟล์รับ `POST` (form-urlencoded) และตอบเป็น JSON

## โครงสร้าง

```
backend/
├─ config.php        ตั้งค่าฐานข้อมูล (แก้ที่เดียว)
├─ bootstrap.php     ทุก Endpoint เรียกเป็นอย่างแรก (Header, CORS, เชื่อมต่อฐานข้อมูล)
├─ ping.php
├─ core/             ฟังก์ชันกลาง: response, auth, helpers, database
├─ auth/             สมัคร / ล็อกอิน / ล็อกเอาต์
├─ user/             เฉพาะฝั่งผู้เบิกวัสดุ (ใช้ User Token)
└─ admin/            เฉพาะฝั่งผู้ดูแลระบบ (ใช้ Admin Token)
```

- โฟลเดอร์ `user/` ใช้ `requireUser` อย่างเดียว โฟลเดอร์ `admin/` ใช้ `requireAdmin` อย่างเดียว
- เพิ่ม Endpoint ใหม่: สร้างไฟล์ในโฟลเดอร์ที่ตรงกับผู้ใช้ แล้วขึ้นต้นด้วย `require_once __DIR__ . '/../bootstrap.php';`

## สร้างบัญชีผู้ดูแลระบบ (Admin) คนแรก

ระบบนี้ไม่มีหน้าสมัคร Admin เอง (ต่างจากผู้เบิกวัสดุที่สมัครเองได้) เพื่อไม่ให้ใครก็เข้ามาสมัครเป็นผู้ดูแลระบบได้ ให้สร้างบัญชีแรกผ่าน:

```
https://โดเมนของคุณ/backend/tools/create_admin.php
```

หน้านี้จะแสดงฟอร์มให้กรอก Username / ชื่อ / อีเมล / รหัสผ่าน **เฉพาะตอนที่ตาราง `admins` ยังไม่มีผู้ดูแลระบบเลยเท่านั้น** สร้างเสร็จแล้วหน้าจะปิดตัวเองอัตโนมัติ (เข้าไปจะเห็นข้อความว่ามีผู้ดูแลระบบอยู่แล้ว) เพิ่มผู้ดูแลระบบคนถัดไปให้ทำผ่านหน้าเว็บ Admin หลังล็อกอินด้วยบัญชีแรกนี้แล้ว

**แนะนำ:** ลบไฟล์ `backend/tools/create_admin.php` ทิ้งจาก Server หลังสร้างบัญชีแรกเสร็จ เพื่อความปลอดภัยสูงสุด แม้หน้าจะปิดใช้งานเองแล้วก็ตาม

## รูปแบบข้อมูล

- ส่ง Token ด้วย Header `Authorization: Bearer <token>` (ส่ง `token` ในตัว request แทนได้)
- สำเร็จ: `{"status":"success", ...}` ผิดพลาด: `{"status":"error","message":"..."}`

## รายการ Endpoint

### ทั่วไป

| URL | สิทธิ์ | รับค่า | ทำอะไร |
|---|---|---|---|
| `/ping.php` | ไม่ต้องล็อกอิน | - | ตรวจว่า API และฐานข้อมูลทำงานอยู่ |

### auth/ (ล็อกอิน)

| URL | สิทธิ์ | รับค่า | ทำอะไร |
|---|---|---|---|
| `/auth/register_user.php` | ไม่ต้องล็อกอิน | `employee_code`, `name`, `email`, `password` | สมัครสมาชิก (ผู้เบิกวัสดุ) |
| `/auth/login_user.php` | ไม่ต้องล็อกอิน | `employee_code`, `password` | เข้าสู่ระบบผู้เบิกวัสดุด้วยรหัสพนักงาน แล้วได้ token |
| `/auth/login_admin.php` | ไม่ต้องล็อกอิน | `username`, `password` | เข้าสู่ระบบผู้ดูแลระบบด้วย Username แล้วได้ token |
| `/auth/logout_user.php` | ส่ง User Token | - | ออกจากระบบ (ยกเลิก session ของผู้เบิกวัสดุ) |
| `/auth/logout_admin.php` | ส่ง Admin Token | - | ออกจากระบบ (ยกเลิก session ของผู้ดูแลระบบ) |

### user/ (ผู้เบิกวัสดุ)

| URL | สิทธิ์ | รับค่า | ทำอะไร |
|---|---|---|---|
| `/user/read_user.php` | User | - | ดูข้อมูลผู้ใช้ที่ล็อกอินอยู่ (ใช้ตรวจว่า session ยังใช้ได้) |
| `/user/read_categories.php` | User | - | รายการหมวดหมู่วัสดุที่เปิดใช้งาน |
| `/user/read_products.php` | User | `search` | รายการวัสดุที่เปิดใช้งาน พร้อมจำนวนคงเหลือ ค้นหาด้วย search ได้ |
| `/user/read_product.php` | User | `id` | รายละเอียดวัสดุ 1 รายการ |
| `/user/create_requisition.php` | User | `purpose`, `required_date`, `items` | สร้างใบเบิกวัสดุ (สถานะเริ่มต้น PENDING) (items = JSON เช่น [{"product_id":1,"quantity":3}] วัสดุซ้ำกันจะถูกรวมจำนวนให้ และแจ้งเตือนผู้ดูแลระบบที่เปิดใช้งานทุกคนว่ามีใบเบิกใหม่รออนุมัติ) |
| `/user/read_requisitions.php` | User | `status` | ใบเบิกของตัวเอง กรองด้วย status ได้ |
| `/user/read_requisition.php` | User | `id` | รายละเอียดใบเบิกของตัวเอง พร้อมรายการวัสดุ |
| `/user/cancel_requisition.php` | User | `id` | ยกเลิกใบเบิกของตัวเอง (ได้เฉพาะสถานะ PENDING) |
| `/user/read_pickup.php` | User | `requisition_id` | ดูรหัส / QR สำหรับรับวัสดุของใบเบิกตัวเอง |
| `/user/read_notifications.php` | User | - | การแจ้งเตือนของตัวเอง |
| `/user/mark_notification_read.php` | User | `id` | ทำเครื่องหมายว่าอ่านการแจ้งเตือนแล้ว |
| `/user/read_status_logs.php` | User | `requisition_id` | ประวัติการเปลี่ยนสถานะของใบเบิกตัวเอง |

### admin/ (ผู้ดูแลระบบ)

| URL | สิทธิ์ | รับค่า | ทำอะไร |
|---|---|---|---|
| `/admin/read_admin.php` | Admin | - | ดูข้อมูลผู้ดูแลที่ล็อกอินอยู่ (ใช้ตรวจว่า session ยังใช้ได้) |
| `/admin/read_categories.php` | Admin | - | รายการหมวดหมู่วัสดุที่เปิดใช้งาน (ใช้เลือกหมวดหมู่ตอนเพิ่ม/แก้ไขวัสดุ) |
| `/admin/read_products.php` | Admin | `search` | รายการวัสดุทั้งหมด (ทุกสถานะ) พร้อมจำนวนคงเหลือ |
| `/admin/read_product.php` | Admin | `id` | รายละเอียดวัสดุ 1 รายการ (ทุกสถานะ) |
| `/admin/upload_product_image.php` | Admin | multipart `product_id`, `image` | อัปโหลดรูป JPG/PNG/WebP (ไม่เกิน 5 MB) ไปยังเซิร์ฟเวอร์ แล้วบันทึก path ใน `products.image_url` |
| `/admin/create_product.php` | Admin | `sku`, `product_name`, `description`, `category_id`, `unit`, `image_url`, `minimum_stock`, `maximum_stock` | เพิ่มวัสดุใหม่ (สร้าง inventory จำนวน 0 ให้อัตโนมัติ) |
| `/admin/update_product.php` | Admin | `id`, `sku`, `product_name`, `description`, `category_id`, `unit`, `image_url`, `minimum_stock`, `maximum_stock`, `status` | แก้ไขข้อมูลวัสดุ |
| `/admin/delete_product.php` | Admin | `id` | ปิดใช้งานวัสดุ (ไม่ลบข้อมูลจริง) |
| `/admin/read_requisitions.php` | Admin | `status` | ใบเบิกทั้งหมด กรองด้วย status ได้ |
| `/admin/read_requisition.php` | Admin | `id` | รายละเอียดใบเบิก 1 ใบ พร้อมรายการวัสดุและข้อมูลผู้เบิก |
| `/admin/approve_requisition.php` | Admin | `id`, `items` | อนุมัติใบเบิก โดยระบุจำนวนที่อนุมัติรายรายการ (PENDING → APPROVED / REJECTED) (items = JSON เช่น [{"item_id":11,"approved_quantity":3}] รายการที่ไม่ส่งมาจะถูกปฏิเสธ) |
| `/admin/reject_requisition.php` | Admin | `id`, `comment` | ปฏิเสธทั้งใบเบิก (PENDING → REJECTED) |
| `/admin/prepare_requisition.php` | Admin | `id` | เริ่มจัดเตรียมวัสดุ (APPROVED (ยังคงสถานะใบเบิก)) |
| `/admin/ready_requisition.php` | Admin | `id` | เตรียมเสร็จ สร้างรหัส / QR รับวัสดุ (APPROVED (พร้อมรับในข้อมูล Pickup)) |
| `/admin/confirm_pickup.php` | Admin | `pickup_code`, `qr_token` | ยืนยันผู้ใช้รับวัสดุแล้วและเปลี่ยนสถานะ APPROVED → ISSUED พร้อมบันทึกประวัติสถานะ ส่ง pickup_code หรือ qr_token อย่างใดอย่างหนึ่ง |
| `/admin/inventory_in.php` | Admin | `product_id`, `quantity` | เพิ่ม Stock |
| `/admin/inventory_adjustment.php` | Admin | `product_id`, `quantity` | ปรับ Stock ให้เป็นจำนวนที่กำหนด |
| `/admin/read_inventory_transactions.php` | Admin | `product_id` | ประวัติการเคลื่อนไหว Stock กรองด้วย product_id ได้ |
| `/admin/read_notifications.php` | Admin | - | การแจ้งเตือนของ Admin |
| `/admin/mark_notification_read.php` | Admin | `id` | ทำเครื่องหมายว่าอ่านการแจ้งเตือนแล้ว |
| `/admin/read_status_logs.php` | Admin | `requisition_id` | ประวัติการเปลี่ยนสถานะของใบเบิกใดก็ได้ |

