import '../../core/utils/json_utils.dart';
import 'requisition_item.dart';

class Requisition {
  final int id;
  final String requestNo;
  final String? purpose;
  final DateTime? requiredDate;
  final String status;
  final int totalItems;
  final int totalQuantity;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? adminComment;
  final List<RequisitionItem> items;

  const Requisition({
    required this.id,
    required this.requestNo,
    this.purpose,
    this.requiredDate,
    required this.status,
    required this.totalItems,
    required this.totalQuantity,
    this.createdAt,
    this.updatedAt,
    this.adminComment,
    this.items = const [],
  });

  bool get canCancel => status == 'PENDING';

  factory Requisition.fromJson(Map<String, dynamic> json) {
    return Requisition(
      id: asInt(json['id']),
      requestNo: asString(json['request_no']),
      purpose: asStringOrNull(json['purpose']),
      requiredDate: asDateTime(json['required_date']),
      status: asString(json['status'], 'PENDING'),
      totalItems: asInt(json['total_items']),
      totalQuantity: asInt(json['total_quantity']),
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
      adminComment: asStringOrNull(json['admin_comment']),
      items: json['items'] is List
          ? asMapList(json['items']).map(RequisitionItem.fromJson).toList()
          : const [],
    );
  }
}
