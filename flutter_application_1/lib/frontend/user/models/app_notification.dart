import '../../core/utils/json_utils.dart';

class AppNotification {
  final int id;
  final String title;
  final String message;
  final String? type;
  final String? referenceType;
  final int? referenceId;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    this.referenceType,
    this.referenceId,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: asInt(json['id']),
      title: asString(json['title']),
      message: asString(json['message']),
      type: asStringOrNull(json['type']),
      referenceType: asStringOrNull(json['reference_type']),
      referenceId: asIntOrNull(json['reference_id']),
      isRead: asBool(json['is_read']),
      createdAt: asDateTime(json['created_at']),
    );
  }
}
