import 'package:flutter/material.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/state_views.dart';
import '../../api/catalog_api.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../state/cart_controller.dart';
import '../../widgets/product_tile.dart';
import 'product_detail_page.dart';

enum _SortBy { nameAsc, stockDesc, stockAsc }

/// รายการวัสดุ ค้นหา + กรองตามหมวดหมู่ได้ เพิ่มลงตะกร้าได้จากในลิสต์เลย
class ProductListPage extends StatefulWidget {
  /// เรียกเมื่อกด "ไปที่รายการเบิก" บนแถบล่าง เพื่อสลับไปแท็บสร้างคำขอ
  final VoidCallback onGoToCart;

  const ProductListPage({super.key, required this.onGoToCart});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  // ---- ค่าสีเฉพาะหน้านี้ (ชุดเดียวกับหน้าเข้าสู่ระบบ) ----
  static const _brand = Color(0xFF1E40AF);
  static const _pageBg = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);

  final _searchController = TextEditingController();
  final _cart = CartController.instance;

  Future<List<Product>>? _future;
  List<Category> _categories = [];
  String _search = '';
  int? _categoryId;
  _SortBy _sort = _SortBy.nameAsc;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCategories();
    _cart.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _load() {
    setState(() {
      _future = CatalogApi.getProducts(search: _search.isEmpty ? null : _search);
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CatalogApi.getCategories();

      if (mounted) setState(() => _categories = categories);
    } catch (_) {
      // แถบหมวดหมู่เป็นส่วนเสริม โหลดไม่สำเร็จก็ไม่ต้องรบกวนผู้ใช้
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _search = value);

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted && _searchController.text == value) {
        _load();
      }
    });
  }

  List<Product> _applyFilters(List<Product> products) {
    var list = _categoryId == null
        ? products
        : products.where((p) => p.categoryId == _categoryId).toList();

    list = [...list];

    switch (_sort) {
      case _SortBy.nameAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case _SortBy.stockDesc:
        list.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
        break;
      case _SortBy.stockAsc:
        list.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
        break;
    }

    return list;
  }

  String get _sortLabel {
    switch (_sort) {
      case _SortBy.nameAsc:
        return 'ชื่อ ก-ฮ';
      case _SortBy.stockDesc:
        return 'คงเหลือมาก';
      case _SortBy.stockAsc:
        return 'คงเหลือน้อย';
    }
  }

  Future<void> _openDetail(Product product) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailPage(productId: product.id)),
    );
  }

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<_SortBy>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'จัดเรียงตาม',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            _SortTile(
              label: 'ชื่อวัสดุ (ก-ฮ)',
              selected: _sort == _SortBy.nameAsc,
              onTap: () => Navigator.of(context).pop(_SortBy.nameAsc),
            ),
            _SortTile(
              label: 'คงเหลือมาก - น้อย',
              selected: _sort == _SortBy.stockDesc,
              onTap: () => Navigator.of(context).pop(_SortBy.stockDesc),
            ),
            _SortTile(
              label: 'คงเหลือน้อย - มาก',
              selected: _sort == _SortBy.stockAsc,
              onTap: () => Navigator.of(context).pop(_SortBy.stockAsc),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() => _sort = picked);
    }
  }

  void _addToCart(Product product) {
    if (product.isOutOfStock) return;

    if (_cart.quantityOf(product.id) >= product.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('มีในตะกร้าครบตามจำนวนคงเหลือแล้ว'),
        ),
      );
      return;
    }

    _cart.add(product, maxQuantity: product.stockQuantity);
  }

  // ---- ส่วนประกอบ UI ----

  Widget _searchField() {
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'ค้นหาชื่อวัสดุ รหัสพัสดุ หรือหมวดหมู่',
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
        prefixIcon: const Icon(Icons.search, size: 22, color: AppColors.muted),
        suffixIcon: _search.isEmpty
            ? null
            : IconButton(
                tooltip: 'ล้างคำค้นหา',
                icon: const Icon(Icons.close, size: 20, color: AppColors.muted),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: outline(_border),
        enabledBorder: outline(_border),
        focusedBorder: outline(_brand, 1.6),
      ),
    );
  }

  Widget _listHeader(int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'พัสดุพร้อมเบิก',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count รายการ',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const Spacer(),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: _border),
            ),
            child: InkWell(
              onTap: _pickSort,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swap_vert, size: 16, color: AppColors.ink),
                    const SizedBox(width: 4),
                    Text(
                      _sortLabel,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _pageBg,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: _searchField(),
              ),
              if (_categories.isNotEmpty)
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      CategoryChip(
                        label: 'ทั้งหมด',
                        selected: _categoryId == null,
                        onTap: () => setState(() => _categoryId = null),
                      ),
                      for (final category in _categories) ...[
                        const SizedBox(width: 8),
                        CategoryChip(
                          label: category.name,
                          selected: _categoryId == category.id,
                          onTap: () =>
                              setState(() => _categoryId = category.id),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Product>>(
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

                    final products = _applyFilters(snapshot.data ?? []);

                    if (products.isEmpty) {
                      return EmptyView(
                        icon: Icons.inventory_2_outlined,
                        title: _search.isEmpty && _categoryId == null
                            ? 'ยังไม่มีวัสดุในระบบ'
                            : 'ไม่พบวัสดุที่ตรงกับตัวกรอง',
                      );
                    }

                    return RefreshIndicator(
                      color: _brand,
                      onRefresh: () async => _load(),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          _cart.isEmpty ? 16 : 100,
                        ),
                        children: [
                          _listHeader(products.length),
                          for (final product in products) ...[
                            ProductTile(
                              product: product,
                              cartQuantity: _cart.quantityOf(product.id),
                              onTap: () => _openDetail(product),
                              onAdd: () => _addToCart(product),
                              onRemove: () => _cart.add(product, by: -1),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (!_cart.isEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _CartSummaryBar(
                itemCount: _cart.itemCount,
                totalQuantity: _cart.totalQuantity,
                onTap: widget.onGoToCart,
              ),
            ),
        ],
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF1E40AF) : AppColors.ink,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: Color(0xFF1E40AF))
          : null,
    );
  }
}

class _CartSummaryBar extends StatelessWidget {
  final int itemCount;
  final int totalQuantity;
  final VoidCallback onTap;

  const _CartSummaryBar({
    required this.itemCount,
    required this.totalQuantity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E40AF),
      borderRadius: BorderRadius.circular(14),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$itemCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เลือกไว้ $itemCount รายการ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'รวมทั้งหมด $totalQuantity ชิ้น',
                      style: const TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'ไปที่รายการเบิก',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}