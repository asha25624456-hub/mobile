import '../../core/api/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../models/category.dart';
import '../models/product.dart';

/// backend/user/read_categories.php, read_products.php, read_product.php
class CatalogApi {
  CatalogApi._();

  static Future<List<Category>> getCategories() async {
    final data = await ApiClient.post(
      'user/read_categories.php',
      auth: true,
    );

    return asMapList(data['data']).map(Category.fromJson).toList();
  }

  static Future<List<Product>> getProducts({String? search}) async {
    final body = <String, String>{};

    if (search != null && search.trim().isNotEmpty) {
      body['search'] = search.trim();
    }

    final data = await ApiClient.post(
      'user/read_products.php',
      body: body,
      auth: true,
    );

    return asMapList(data['data']).map(Product.fromJson).toList();
  }

  static Future<Product> getProduct(int productId) async {
    final data = await ApiClient.post(
      'user/read_product.php',
      body: {'id': productId.toString()},
      auth: true,
    );

    return Product.fromJson(Map<String, dynamic>.from(data['data'] ?? {}));
  }
}
