/// ค่าตั้งต้นของแอป: แก้ที่ไฟล์นี้ไฟล์เดียว
class AppConfig {
  AppConfig._();

  /// API ที่ใช้ร่วมกันระหว่างแอปและหน้าแอดมิน web2 (ไม่ต้องมี / ปิดท้าย)
  /// web2/index.php ตั้งค่า API เป็น ../backend จึงต้องชี้มาที่ backend
  /// โฟลเดอร์เดียวกัน ไม่ใช่ URL ของหน้า web2 เอง
  static const String baseUrl =
      'https://std.mcs.psu.ac.th/6620310027/html/apinew/backend';

  /// โฟลเดอร์รูปเดิมที่หน้า web2 ใช้ (อยู่ระดับเดียวกับ backend)
  static const String uploadsUrl =
      'https://std.mcs.psu.ac.th/6620310027/html/apinew/uploads';

  static const String appName = 'ระบบเบิกวัสดุ';
}
