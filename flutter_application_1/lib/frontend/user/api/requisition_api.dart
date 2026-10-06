import 'dart:convert';

import '../../core/api/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../models/pickup.dart';
import '../models/requisition.dart';
import '../models/status_log.dart';

/// backend/user/ ที่เกี่ยวกับใบเบิก
class RequisitionApi {
  RequisitionApi._();

  /// สร้างใบเบิก คืน (id, request_no) ของใบที่สร้าง
  static Future<Map<String, dynamic>> create({
    String? purpose,
    String? requiredDate,
    required List<Map<String, int>> items,
  }) async {
    final data = await ApiClient.post(
      'user/create_requisition.php',
      auth: true,
      body: {
        if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
        if (requiredDate != null && requiredDate.isNotEmpty)
          'required_date': requiredDate,
        'items': jsonEncode(items),
      },
    );

    return data;
  }

  static Future<List<Requisition>> list({String? status}) async {
    final data = await ApiClient.post(
      'user/read_requisitions.php',
      auth: true,
      body: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    return asMapList(data['data']).map(Requisition.fromJson).toList();
  }

  static Future<Requisition> detail(int id) async {
    final data = await ApiClient.post(
      'user/read_requisition.php',
      auth: true,
      body: {'id': id.toString()},
    );

    return Requisition.fromJson(Map<String, dynamic>.from(data['data'] ?? {}));
  }

  static Future<void> cancel(int id) async {
    await ApiClient.post(
      'user/cancel_requisition.php',
      auth: true,
      body: {'id': id.toString()},
    );
  }

  /// คืน null ถ้ายังไม่มีรหัสรับวัสดุ (ใบเบิกยังไม่ได้รับอนุมัติหรือยังเตรียมไม่เสร็จ)
  static Future<Pickup?> pickup(int requisitionId) async {
    try {
      final data = await ApiClient.post(
        'user/read_pickup.php',
        auth: true,
        body: {'requisition_id': requisitionId.toString()},
      );

      return Pickup.fromJson(Map<String, dynamic>.from(data['data'] ?? {}));
    } catch (_) {
      return null;
    }
  }

  static Future<List<StatusLog>> statusLogs(int requisitionId) async {
    final data = await ApiClient.post(
      'user/read_status_logs.php',
      auth: true,
      body: {'requisition_id': requisitionId.toString()},
    );

    return asMapList(data['data']).map(StatusLog.fromJson).toList();
  }
}
