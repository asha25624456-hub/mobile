import '../../core/utils/json_utils.dart';

class Product {
  final int id;
  final String sku;
  final String name;
  final String? description;
  final int? categoryId;
  final String? categoryName;
  final String unit;
  final String? imageUrl;
  final int minimumStock;
  final int maximumStock;
  final String status;
  final int stockQuantity;

  const Product({
    required this.id,
    required this.sku,
    required this.name,
    this.description,
    this.categoryId,
    this.categoryName,
    required this.unit,
    this.imageUrl,
    required this.minimumStock,
    required this.maximumStock,
    required this.status,
    required this.stockQuantity,
  });

  bool get isLowStock => stockQuantity <= minimumStock;
  bool get isOutOfStock => stockQuantity <= 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    final name = asString(json['product_name']);
    final imageUrl = asStringOrNull(json['image_url']) ??
        asStringOrNull(json['product_image']) ??
        _legacyImageFor(name);

    return Product(
      id: asInt(json['id']),
      sku: asString(json['sku']),
      name: name,
      description: asStringOrNull(json['description']),
      categoryId: asIntOrNull(json['category_id']),
      categoryName: asStringOrNull(json['category_name']),
      unit: asString(json['unit']),
      imageUrl: imageUrl,
      minimumStock: asInt(json['minimum_stock']),
      maximumStock: asInt(json['maximum_stock']),
      status: asString(json['status'], 'ACTIVE'),
      stockQuantity: asInt(json['stock_quantity']),
    );
  }

  /// Keep the same legacy image fallback used by the web2 admin page for
  /// older products that do not yet have image_url saved in the database.
  static String? _legacyImageFor(String name) {
    const images = <String, String>{
      'ดินสอไม้ HB': 'pencil-hb.jpg',
      'กล่องเก็บเอกสารพลาสติก': 'plastic-document-box.jpg',
      'กล่องแฟ้มเอกสาร': 'document-file-box.jpg',
      'ลูกฟุตบอล': 'football.jpg',
      'กล่องเอกสารขนาด A4': 'a4-document-box.jpg',
    };
    final normalizedName = name.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    for (final entry in images.entries) {
      if (entry.key.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase() ==
          normalizedName) {
        return 'uploads/${entry.value}';
      }
    }
    return null;
  }
}
