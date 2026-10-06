import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../session/session_manager.dart';
import 'api_exceptions.dart';

/// ตัวกลางเรียก Backend ทุก Endpoint (ใช้ร่วมกันทั้ง auth / user)
class ApiClient {
  ApiClient._();

  static const Duration _timeout = Duration(seconds: 20);

  /// [path] เช่น 'user/read_products.php'
  /// [auth] true = แนบ Token ของผู้เบิกวัสดุที่ล็อกอินอยู่ให้อัตโนมัติ
  /// [handleExpiry] true = ถ้า Token หมดอายุ ล้าง session แล้วพากลับหน้าล็อกอิน
  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String> body = const {},
    bool auth = false,
    bool handleExpiry = true,
  }) async {
    String? token;

    if (auth) {
      token = SessionManager.token;

      if (token == null || token.isEmpty) {
        throw const SessionExpiredException('กรุณาเข้าสู่ระบบก่อน');
      }
    }

    try {
      final headers = <String, String>{};
      final payload = Map<String, String>.from(body);

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        // สำรองไว้ เผื่อ Hosting ตัด Header Authorization ทิ้ง
        payload['token'] = token;
      }

      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/$path'),
            headers: headers,
            body: payload,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw ApiException(
          'ไม่สามารถเชื่อมต่อ Server ได้ (${response.statusCode})',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map) {
        throw const ApiException('รูปแบบข้อมูลจาก Server ไม่ถูกต้อง');
      }

      final result = Map<String, dynamic>.from(decoded);

      if (result['status'] == 'error') {
        final message =
            result['message']?.toString() ?? 'เกิดข้อผิดพลาดจาก Server';
        final code = result['code']?.toString();

        if (code == 'SESSION_EXPIRED' || code == 'AUTH_REQUIRED') {
          if (handleExpiry) {
            await SessionManager.clear();
            SessionManager.notifyExpired();
          }

          throw SessionExpiredException(message);
        }

        throw ApiException(message, code: code);
      }

      return result;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('เชื่อมต่อ Server หมดเวลา กรุณาลองใหม่อีกครั้ง');
    } on FormatException {
      throw const ApiException('รูปแบบข้อมูลจาก Server ไม่ถูกต้อง');
    } catch (e) {
      debugPrint('ApiClient error ($path): $e');

      throw const ApiException(
        'ไม่สามารถเชื่อมต่อ Server ได้ กรุณาตรวจสอบอินเทอร์เน็ต',
      );
    }
  }
}
