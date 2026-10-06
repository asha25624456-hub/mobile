import 'package:flutter/foundation.dart';

import '../models/product.dart';

class CartLine {
  final Product product;
  int quantity;

  CartLine({required this.product, required this.quantity});
}

/// ตะกร้าเลือกวัสดุก่อนส่งเป็นใบเบิก อยู่ในหน่วยความจำ (ไม่บันทึกลงเครื่อง)
/// ตัวเดียวใช้ร่วมกันทั้งแอป (Singleton) เพราะมีตะกร้าเดียวต่อการล็อกอิน 1 ครั้ง
class CartController extends ChangeNotifier {
  CartController._();

  static final CartController instance = CartController._();

  final Map<int, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList(growable: false);

  int get itemCount => _lines.length;

  int get totalQuantity =>
      _lines.values.fold(0, (sum, line) => sum + line.quantity);

  bool get isEmpty => _lines.isEmpty;

  int quantityOf(int productId) => _lines[productId]?.quantity ?? 0;

  /// เพิ่มวัสดุ 1 ชิ้นลงตะกร้า (หรือเพิ่มจำนวนถ้ามีอยู่แล้ว)
  /// [maxQuantity] ถ้าระบุ จะไม่ให้เกินจำนวนนี้ (เช่น Stock คงเหลือ)
  void add(Product product, {int by = 1, int? maxQuantity}) {
    final existing = _lines[product.id];
    final nextQty = (existing?.quantity ?? 0) + by;
    final capped = maxQuantity == null ? nextQty : nextQty.clamp(0, maxQuantity);

    if (capped <= 0) {
      _lines.remove(product.id);
    } else if (existing == null) {
      _lines[product.id] = CartLine(product: product, quantity: capped);
    } else {
      existing.quantity = capped;
    }

    notifyListeners();
  }

  void setQuantity(Product product, int quantity, {int? maxQuantity}) {
    final capped =
        maxQuantity == null ? quantity : quantity.clamp(0, maxQuantity);

    if (capped <= 0) {
      _lines.remove(product.id);
    } else {
      _lines[product.id] = CartLine(product: product, quantity: capped);
    }

    notifyListeners();
  }

  void remove(int productId) {
    if (_lines.remove(productId) != null) {
      notifyListeners();
    }
  }

  void clear() {
    if (_lines.isEmpty) return;

    _lines.clear();
    notifyListeners();
  }

  List<Map<String, int>> toRequisitionItems() {
    return _lines.values
        .map((line) => {'product_id': line.product.id, 'quantity': line.quantity})
        .toList();
  }
}
