import '../../core/utils/json_utils.dart';

class Pickup {
  final int id;
  final int requisitionId;
  final String pickupCode;
  final String qrToken;
  final String status;
  final DateTime? preparedAt;
  final DateTime? pickedUpAt;

  const Pickup({
    required this.id,
    required this.requisitionId,
    required this.pickupCode,
    required this.qrToken,
    required this.status,
    this.preparedAt,
    this.pickedUpAt,
  });

  factory Pickup.fromJson(Map<String, dynamic> json) {
    return Pickup(
      id: asInt(json['id']),
      requisitionId: asInt(json['requisition_id']),
      pickupCode: asString(json['pickup_code']),
      qrToken: asString(json['qr_token']),
      status: asString(json['status'], 'WAITING'),
      preparedAt: asDateTime(json['prepared_at']),
      pickedUpAt: asDateTime(json['picked_up_at']),
    );
  }
}
