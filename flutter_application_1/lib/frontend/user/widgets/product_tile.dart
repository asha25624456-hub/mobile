import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/stock_labels.dart';
import '../../core/widgets/status_chip.dart';
import '../models/product.dart';
import 'product_image.dart';

const _brand = Color(0xFF0F2A5C);

/// ชุดสีของการ์ด แยกตามสถานะ (ปกติ / อยู่ในตะกร้า / หมด)
/// พื้นการ์ดเป็นสีขาวสะอาด ใช้สีเฉพาะแถบข้าง ขอบ และพื้นแถบล่าง
class _BoxTheme {
  final Color background;
  final Color border;
  final Color accent;
  final Color footer;
  final Color imageBg;
  final List<BoxShadow> shadows;

  const _BoxTheme({
    required this.background,
    required this.border,
    required this.accent,
    required this.footer,
    required this.imageBg,
    required this.shadows,
  });

  static const normal = _BoxTheme(
    background: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    accent: Color(0xFFCBD5E1),
    footer: Color(0xFFF8FAFC),
    imageBg: Color(0xFFF1F5F9),
    shadows: [
      BoxShadow(
        color: Color(0x0A0F172A),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
      BoxShadow(
        color: Color(0x0D0F172A),
        blurRadius: 16,
        offset: Offset(0, 6),
      ),
    ],
  );

  static const inCart = _BoxTheme(
    background: Color(0xFFF7FAFF),
    border: Color(0xFF9DB2D9),
    accent: _brand,
    footer: Color(0xFFEDF2FB),
    imageBg: Color(0xFFE6EDF8),
    shadows: [
      BoxShadow(
        color: Color(0x0F0F2A5C),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
      BoxShadow(
        color: Color(0x1F0F2A5C),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ],
  );

  static const outOfStock = _BoxTheme(
    background: Color(0xFFFAFBFC),
    border: Color(0xFFE5E9EF),
    accent: Color(0xFFE2E8F0),
    footer: Color(0xFFF3F5F8),
    imageBg: Color(0xFFEAEEF3),
    shadows: [
      BoxShadow(
        color: Color(0x060F172A),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );
}

class ProductTile extends StatelessWidget {
  final Product product;
  final int cartQuantity;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const ProductTile({
    super.key,
    required this.product,
    required this.cartQuantity,
    required this.onTap,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.isOutOfStock;
    final inCart = cartQuantity > 0 && !outOfStock;
    final category = product.categoryName;

    final theme = outOfStock
        ? _BoxTheme.outOfStock
        : (inCart ? _BoxTheme.inCart : _BoxTheme.normal);

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border, width: inCart ? 1.4 : 1),
        boxShadow: theme.shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(inCart ? 16.6 : 17),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // แถบสีด้านซ้ายบอกสถานะ
                  Container(width: 5, color: theme.accent),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ---- ส่วนบน: ข้อมูลวัสดุ (จางลงเมื่อหมด) ----
                        Opacity(
                          opacity: outOfStock ? 0.55 : 1,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _imagePanel(theme, inCart),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15.5,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 8,
                                        children: [
                                          Text(
                                            product.sku,
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 12.5,
                                              height: 1.5,
                                            ),
                                          ),
                                          if (category != null) ...[
                                            Container(
                                              width: 1,
                                              height: 11,
                                              color: const Color(0xFFCBD5E1),
                                            ),
                                            Text(
                                              category,
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 12.5,
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ---- ส่วนล่าง: สต็อก + ตัวปรับจำนวน ----
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                          decoration: BoxDecoration(
                            color: theme.footer,
                            border: const Border(
                              top: BorderSide(
                                color: Color(0xFFEEF1F5),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Opacity(
                                    opacity: outOfStock ? 0.7 : 1,
                                    child: StatusChip(
                                      stockStatusStyle(product),
                                      small: true,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _QuantityStepper(
                                quantity: cartQuantity,
                                disabled: outOfStock,
                                onAdd: onAdd,
                                onRemove: onRemove,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// รูปสินค้าในแผ่นรองสีอ่อน + ป้ายติ๊กถูกเมื่ออยู่ในตะกร้า
  Widget _imagePanel(_BoxTheme theme, bool inCart) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: theme.imageBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ProductImage(
              imageUrl: product.imageUrl,
              width: 60,
              height: 60,
              radius: 10,
              iconSize: 26,
            ),
          ),
          if (inCart)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _brand,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final bool disabled;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const _QuantityStepper({
    required this.quantity,
    required this.disabled,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (disabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'หมด',
          style: TextStyle(
            color: AppColors.errorText,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      );
    }

    // ยังไม่มีในตะกร้า: ปุ่มเพิ่มสีกรมท่าทึบ
    if (quantity <= 0) {
      return Material(
        color: _brand,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: 'เพิ่มลงรายการเบิก',
          child: InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'เบิก',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // มีในตะกร้าแล้ว: ปุ่มลด - จำนวน - ปุ่มเพิ่ม ในแคปซูลขอบบาง
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD5DEEC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            tooltip: 'ลดจำนวน',
            onTap: onRemove,
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: 'เพิ่มจำนวน',
            onTap: onAdd,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool filled;

  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? _brand : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 19,
              color: filled ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}