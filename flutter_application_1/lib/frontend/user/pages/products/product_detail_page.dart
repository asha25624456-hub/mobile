import 'package:flutter/material.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/stock_labels.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../api/catalog_api.dart';
import '../../models/product.dart';
import '../../state/cart_controller.dart';
import '../../widgets/product_image.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  // ---- ค่าสีเฉพาะหน้านี้ (ชุดเดียวกับหน้าอื่น) ----
  static const _brand = Color(0xFF1E40AF);
  static const _pageBg = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);

  late Future<Product> _future;
  final _cart = CartController.instance;

  @override
  void initState() {
    super.initState();
    _load();
    _cart.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _load() {
    setState(() {
      _future = CatalogApi.getProduct(widget.productId);
    });
  }

  // ---- ส่วนประกอบ UI ----

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      );

  Widget _infoRow(String label, String value, {bool last = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!last) const Divider(height: 1, color: _border),
      ],
    );
  }

  Widget _content(Product product) {
    final hasDescription =
        product.description != null && product.description!.isNotEmpty;
    final category = product.categoryName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: ProductImage(
            imageUrl: product.imageUrl,
            width: 84,
            height: 84,
            radius: 20,
            iconSize: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: StatusChip(stockStatusStyle(product)),
        ),
        const SizedBox(height: 20),
        _card(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('ข้อมูลวัสดุ'),
              const SizedBox(height: 4),
              _infoRow('รหัสพัสดุ', product.sku),
              if (category != null) _infoRow('หมวดหมู่', category),
              _infoRow(
                'คงเหลือ',
                '${product.stockQuantity} ${product.unit}',
                last: true,
              ),
            ],
          ),
        ),
        if (hasDescription) ...[
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('รายละเอียด'),
                const SizedBox(height: 10),
                Text(
                  product.description!,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _actionBar(Product product) {
    final qty = _cart.quantityOf(product.id);

    final Widget action;

    if (product.isOutOfStock) {
      action = Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 18, color: AppColors.errorText),
            SizedBox(width: 8),
            Text(
              'วัสดุนี้หมดชั่วคราว',
              style: TextStyle(
                color: AppColors.errorText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (qty <= 0) {
      action = PrimaryButton(
        label: 'เพิ่มลงตะกร้า',
        icon: Icons.add_shopping_cart,
        onPressed: () => _cart.add(product, maxQuantity: product.stockQuantity),
      );
    } else {
      action = Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            _StepButton(
              icon: Icons.remove,
              tooltip: 'ลดจำนวน',
              onTap: () => _cart.add(product, by: -1),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$qty ${product.unit} ในตะกร้า',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              tooltip: 'เพิ่มจำนวน',
              filled: true,
              onTap: qty >= product.stockQuantity
                  ? null
                  : () =>
                      _cart.add(product, maxQuantity: product.stockQuantity),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: action,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text(
          'รายละเอียดวัสดุ',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: _pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: FutureBuilder<Product>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          if (snapshot.hasError) {
            return ErrorView(
              message: errorMessageOf(snapshot.error!),
              onRetry: _load,
            );
          }

          final product = snapshot.data!;

          return Column(
            children: [
              Expanded(child: _content(product)),
              _actionBar(product),
            ],
          );
        },
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  static const _brand = Color(0xFF1E40AF);

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
    final radius = BorderRadius.circular(12);
    final disabled = onTap == null;

    final Color bg = filled
        ? (disabled ? AppColors.line : _brand)
        : Colors.transparent;
    final Color fg = filled
        ? Colors.white
        : (disabled ? AppColors.line : AppColors.muted);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, size: 22, color: fg),
          ),
        ),
      ),
    );
  }
}
