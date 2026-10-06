import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// เก็บ Token + ข้อมูลผู้เบิกวัสดุที่ล็อกอินอยู่ ทั้งในหน่วยความจำและในเครื่อง
/// (ปิดแอปแล้วเปิดใหม่ยังล็อกอินต่อได้)
///
/// แอปนี้มีไว้สำหรับผู้เบิกวัสดุเท่านั้น ฝั่งผู้ดูแลระบบใช้งานผ่านหน้าเว็บ Admin แยกต่างหาก
class SessionManager {
  SessionManager._();

  static const _kToken = 'session_token';
  static const _kProfile = 'session_profile';

  static String? token;
  static Map<String, dynamic> profile = {};

  /// เพิ่มค่าทุกครั้งที่ session หมดอายุกลางทาง
  /// main.dart ฟังตัวนี้แล้วพากลับหน้าล็อกอิน
  static final ValueNotifier<int> expiredEvents = ValueNotifier<int>(0);

  static bool get isLoggedIn => token != null && token!.isNotEmpty;

  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();

    token = prefs.getString(_kToken);
    profile = {};

    final savedProfile = prefs.getString(_kProfile);

    if (savedProfile != null) {
      try {
        final decoded = jsonDecode(savedProfile);

        if (decoded is Map) {
          profile = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        profile = {};
      }
    }

    if (token != null && token!.isEmpty) {
      token = null;
    }
  }

  static Future<void> save({
    required String token,
    required Map<String, dynamic> profile,
  }) async {
    SessionManager.token = token;
    SessionManager.profile = profile;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_kToken, token);
    await prefs.setString(_kProfile, jsonEncode(profile));
  }

  static Future<void> updateProfile(Map<String, dynamic> newProfile) async {
    profile = newProfile;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_kProfile, jsonEncode(newProfile));
  }

  static Future<void> clear() async {
    token = null;
    profile = {};

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_kToken);
    await prefs.remove(_kProfile);
  }

  static void notifyExpired() {
    expiredEvents.value++;
  }
}
