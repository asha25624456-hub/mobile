import '../../core/utils/json_utils.dart';

class RequisitionItem {
  final int id;
  final int productId;
  final String sku;
  final String productName;
  final int requestedQuantity;
  final int approvedQuantity;
  final int pickedQuantity;
  final int issuedQuantity;
  final String unit;
  final String status;

  const RequisitionItem({
    required this.id,
    required this.productId,
    required this.sku,
    required this.productName,
    required this.requestedQuantity,
    required this.approvedQuantity,
    required this.pickedQuantity,
    required this.issuedQuantity,
    required this.unit,
    required this.status,
  });

  factory RequisitionItem.fromJson(Map<String, dynamic> json) {
    return RequisitionItem(
      id: asInt(json['id']),
      productId: asInt(json['product_id']),
      sku: asString(json['sku']),
      productName: asString(json['product_name']),
      requestedQuantity: asInt(json['requested_quantity']),
      approvedQuantity: asInt(json['approved_quantity']),
      pickedQuantity: asInt(json['picked_quantity']),
      issuedQuantity: asInt(json['issued_quantity']),
      unit: asString(json['unit']),
      status: asString(json['status'], 'PENDING'),
    );
  }
}
