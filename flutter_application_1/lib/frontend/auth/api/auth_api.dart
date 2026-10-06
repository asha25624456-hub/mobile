import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/session/session_manager.dart';

/// Endpoint ในโฟลเดอร์ backend/auth/ + ตรวจ session
/// (แอปนี้สำหรับผู้เบิกวัสดุเท่านั้น ฝั่งผู้ดูแลระบบใช้หน้าเว็บ Admin แยกต่างหาก)
class AuthApi {
  AuthApi._();

  /// backend/ping.php
  static Future<bool> ping() async {
    final data = await ApiClient.post('ping.php');

    return data['status'] == 'success';
  }

  /// backend/auth/register_user.php
  static Future<Map<String, dynamic>> registerUser({
    required String employeeCode,
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.post('auth/register_user.php', body: {
      'employee_code': employeeCode,
      'name': name,
      'email': email,
      'password': password,
    });

    return Map<String, dynamic>.from(data['user'] ?? {});
  }

  /// backend/auth/login_user.php  (สำเร็จแล้วบันทึก session ให้อัตโนมัติ)
  static Future<Map<String, dynamic>> loginUser({
    required String employeeCode,
    required String password,
  }) async {
    final data = await ApiClient.post('auth/login_user.php', body: {
      'employee_code': employeeCode,
      'password': password,
    });

    final token = data['token']?.toString();

    if (token == null || token.isEmpty) {
      throw const ApiException('ไม่พบ User Token');
    }

    final profile = Map<String, dynamic>.from(data['user'] ?? {});

    await SessionManager.save(token: token, profile: profile);

    return profile;
  }

  /// backend/user/read_user.php  ตรวจว่า session ยังใช้ได้ และอัปเดตข้อมูลผู้ใช้
  static Future<Map<String, dynamic>> fetchUser({
    bool handleExpiry = true,
  }) async {
    final data = await ApiClient.post(
      'user/read_user.php',
      auth: true,
      handleExpiry: handleExpiry,
    );

    final profile = Map<String, dynamic>.from(data['user'] ?? {});

    await SessionManager.updateProfile(profile);

    return profile;
  }

  /// backend/auth/logout_user.php
  /// ล้าง session ในเครื่องเสมอ แม้ Server ตอบกลับไม่ได้
  static Future<void> logout() async {
    if (!SessionManager.isLoggedIn) {
      return;
    }

    try {
      await ApiClient.post(
        'auth/logout_user.php',
        auth: true,
        handleExpiry: false,
      );
    } catch (_) {
      // ไม่เป็นไร ล้างฝั่งแอปต่อได้
    } finally {
      await SessionManager.clear();
    }
  }
}
