import 'package:flutter/material.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/message_banner.dart';
import '../../../core/widgets/state_views.dart';
import '../../api/requisition_api.dart';
import '../../state/cart_controller.dart';

/// แท็บ "สร้างคำขอ": ตะกร้าวัสดุที่เลือกไว้ + ข้อมูลผู้เบิก + ยืนยันส่งเป็นใบเบิก 1 ใบ
class BuildRequestPage extends StatefulWidget {
  /// เรียกเมื่อกด "เลือกพัสดุเพิ่มจากแคตตาล็อก" เพื่อสลับไปแท็บวัสดุ
  final VoidCallback onGoToProducts;

  /// เรียกเมื่อส่งใบเบิกสำเร็จ พร้อมรหัสใบเบิกใหม่ (ให้พาไปแท็บติดตามสถานะ)
  final ValueChanged<int?> onSubmitted;

  const BuildRequestPage({
    super.key,
    required this.onGoToProducts,
    required this.onSubmitted,
  });

  @override
  State<BuildRequestPage> createState() => _BuildRequestPageState();
}

class _BuildRequestPageState extends State<BuildRequestPage> {
  // ---- พาเลตต์: กรมท่า / เทา (ชุดเดียวกับหน้าอื่น) ----
  static const _navy = Color(0xFF0F2A5C);
  static const _grayBg = Color(0xFFF1F5F9);
  static const _pageBg = Color(0xFFF5F7FA);
  static const _fieldBg = Color(0xFFF8FAFC);
  static const _line = Color(0xFFE2E8F0);
  static const _divider = Color(0xFFEEF1F5);
  static const _hint = Color(0xFF94A3B8);

  static const _shadows = [
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
  ];

  final _cart = CartController.instance;
  final _purposeController = TextEditingController();
  DateTime? _requiredDate;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cart.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    _purposeController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _requiredDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _requiredDate = picked);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final requiredDate = _requiredDate == null
          ? null
          : '${_requiredDate!.year}-${_requiredDate!.month.toString().padLeft(2, '0')}-${_requiredDate!.day.toString().padLeft(2, '0')}';

      final result = await RequisitionApi.create(
        purpose: _purposeController.text.trim(),
        requiredDate: requiredDate,
        items: _cart.toRequisitionItems(),
      );

      _cart.clear();
      _purposeController.clear();

      final newId = result['id'];

      setState(() => _requiredDate = null);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('ส่งใบเบิกสำเร็จ'),
        ),
      );

      widget.onSubmitted(newId is int ? newId : null);
    } catch (e) {
      if (!mounted) return;

      setState(() => _error = errorMessageOf(e));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  // ---- ส่วนประกอบ UI ----

  /// การ์ดขาว ขอบบาง เงานุ่ม
  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
        boxShadow: _shadows,
      ),
      child: child,
    );
  }

  /// หัวข้อส่วน: แถบกรมท่านำหน้า + จำนวนรายการเป็นแคปซูลเทา
  Widget _sectionTitle(String text, {String? trailing}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _grayBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              trailing,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _fieldLabel(String text, {bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              height: 1.5,
            ),
          ),
          if (optional) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: _grayBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'ไม่บังคับ',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.muted,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hint, IconData? icon}) {
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _hint, fontSize: 15),
      prefixIcon:
          icon == null ? null : Icon(icon, size: 20, color: AppColors.muted),
      filled: true,
      fillColor: _fieldBg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: outline(_line),
      enabledBorder: outline(_line),
      focusedBorder: outline(_navy, 1.6),
    );
  }

  /// การ์ดผู้เบิก: อวาตาร์กรมท่า (ตัวอักษรแรกของชื่อ) + รหัสพนักงานเป็นแคปซูล
  Widget _requesterCard(Map profile) {
    final name = profile['name']?.toString() ?? '-';
    final code = profile['employee_code']?.toString() ?? '-';
    final initial = name.isNotEmpty && name != '-'
        ? String.fromCharCodes([name.runes.first])
        : '?';

    return _card(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: _navy,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    color: AppColors.ink,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: _grayBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'รหัสพนักงาน $code',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel('วัตถุประสงค์การเบิก', optional: true),
          TextField(
            controller: _purposeController,
            maxLines: 2,
            style: const TextStyle(fontSize: 15, height: 1.5),
            decoration: _fieldDecoration(
              hint: 'เช่น ใช้สำหรับโครงการหรือกิจกรรมใด',
            ),
          ),
          const SizedBox(height: 20),
          _fieldLabel('วันที่ต้องการใช้งานพัสดุ', optional: true),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: _fieldDecoration(icon: Icons.event_rounded),
              child: Text(
                _requiredDate == null
                    ? 'เลือกวันที่'
                    : '${_requiredDate!.day}/${_requiredDate!.month}/${_requiredDate!.year + 543}',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: _requiredDate == null ? _hint : AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// การ์ดพัสดุ: แถบกรมท่าด้านซ้าย + เลขลำดับ + ตัวปรับจำนวน
  Widget _lineCard(dynamic line, int index) {
    final atLimit = line.quantity >= line.product.stockQuantity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line),
          boxShadow: _shadows,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: _navy),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _grayBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _line),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$index',
                                style: const TextStyle(
                                  color: _navy,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: AppColors.ink,
                                      height: 1.5,
                                    ),
                                  ),
                                  Text(
                                    line.product.sku,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12.5,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'นำออกจากรายการ',
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 22,
                              ),
                              color: AppColors.errorText,
                              onPressed: () => _cart.remove(line.product.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 1, color: _divider),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'คงเหลือ ${line.product.stockQuantity}',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    ),
                                    if (atLimit)
                                      const Text(
                                        'ถึงจำนวนสูงสุดแล้ว',
                                        style: TextStyle(
                                          color: _navy,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          height: 1.5,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              _QtyStepper(
                                quantity: line.quantity,
                                canIncrease: !atLimit,
                                onRemove: () => _cart.add(line.product, by: -1),
                                onAdd: () => _cart.add(
                                  line.product,
                                  maxQuantity: line.product.stockQuantity,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(int itemCount) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                MessageBanner(_error!),
                const SizedBox(height: 12),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _grayBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'จำนวนรวม',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_cart.totalQuantity} ชิ้น',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: _navy,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($itemCount รายการ)',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'ส่งคำขอเบิก',
                icon: Icons.send_rounded,
                loading: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = _cart.lines;
    final profile = SessionManager.profile;

    if (lines.isEmpty) {
      return const ColoredBox(
        color: _pageBg,
        child: EmptyView(
          icon: Icons.playlist_add_rounded,
          title: 'ยังไม่ได้เลือกวัสดุ',
          subtitle: 'ไปที่แท็บ "พัสดุ" แล้วกด + เพื่อเพิ่มลงตะกร้า',
        ),
      );
    }

    return ColoredBox(
      color: _pageBg,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                _sectionTitle('ข้อมูลผู้เบิกและปลายทาง'),
                const SizedBox(height: 12),
                _requesterCard(profile),
                const SizedBox(height: 28),
                _sectionTitle('รายละเอียดการเบิก'),
                const SizedBox(height: 12),
                _detailsCard(),
                const SizedBox(height: 28),
                _sectionTitle(
                  'รายการพัสดุที่ขอเบิก',
                  trailing: '${lines.length} รายการ',
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < lines.length; i++) _lineCard(lines[i], i + 1),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: widget.onGoToProducts,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('เลือกพัสดุเพิ่มจากแคตตาล็อก'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    backgroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: _navy, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _bottomBar(lines.length),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  static const _navy = Color(0xFF0F2A5C);
  static const _fieldBg = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);

  final int quantity;
  final bool canIncrease;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  const _QtyStepper({
    required this.quantity,
    required this.canIncrease,
    required this.onRemove,
    required this.onAdd,
  });

  Widget _button({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    bool filled = false,
  }) {
    final radius = BorderRadius.circular(10);
    final disabled = onTap == null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? (disabled ? _border : _navy) : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 18,
              color: filled
                  ? Colors.white
                  : (disabled ? _border : AppColors.muted),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(
            icon: Icons.remove_rounded,
            tooltip: 'ลดจำนวน',
            onTap: onRemove,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
          ),
          _button(
            icon: Icons.add_rounded,
            tooltip: 'เพิ่มจำนวน',
            filled: true,
            onTap: canIncrease ? onAdd : null,
          ),
        ],
      ),
    );
  }
}