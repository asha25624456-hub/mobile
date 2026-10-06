import '../../core/utils/json_utils.dart';

class Category {
  final int id;
  final String code;
  final String name;
  final String? description;

  const Category({
    required this.id,
    required this.code,
    required this.name,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: asInt(json['id']),
      code: asString(json['category_code']),
      name: asString(json['category_name']),
      description: asStringOrNull(json['description']),
    );
  }
}
