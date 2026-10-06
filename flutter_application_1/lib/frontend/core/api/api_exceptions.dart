/// ข้อผิดพลาดที่ Server ตอบกลับ (หรือเชื่อมต่อไม่ได้)
/// toString() คืนข้อความภาษาไทยพร้อมแสดงให้ผู้ใช้ได้เลย
class ApiException implements Exception {
  final String message;
  final String? code;

  const ApiException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Token ไม่ถูกต้อง / หมดอายุ / ยังไม่ได้ล็อกอิน
class SessionExpiredException extends ApiException {
  const SessionExpiredException([
    String message = 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่',
  ]) : super(message, code: 'SESSION_EXPIRED');
}

/// แปลง error อะไรก็ได้เป็นข้อความที่แสดงให้ผู้ใช้อ่านได้
String errorMessageOf(Object error) {
  if (error is ApiException) {
    return error.message;
  }

  return error.toString().replaceFirst('Exception: ', '');
}
