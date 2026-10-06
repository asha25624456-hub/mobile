import '../../core/utils/json_utils.dart';

class StatusLog {
  final int id;
  final String? fromStatus;
  final String toStatus;
  final String? comment;
  final DateTime? createdAt;

  const StatusLog({
    required this.id,
    this.fromStatus,
    required this.toStatus,
    this.comment,
    this.createdAt,
  });

  factory StatusLog.fromJson(Map<String, dynamic> json) {
    return StatusLog(
      id: asInt(json['id']),
      fromStatus: asStringOrNull(json['from_status']),
      toStatus: asString(json['to_status']),
      comment: asStringOrNull(json['comment']),
      createdAt: asDateTime(json['created_at']),
    );
  }
}
