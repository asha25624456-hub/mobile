import 'package:flutter/material.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/message_banner.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../api/requisition_api.dart';
import '../../models/requisition.dart';
import '../../models/status_log.dart';
import '../../widgets/requisition_timeline.dart';

class RequisitionDetailPage extends StatefulWidget {
  final int requisitionId;
  final bool showTimeline;

  const RequisitionDetailPage({
    super.key,
    required this.requisitionId,
    this.showTimeline = true,
  });

  @override
  State<RequisitionDetailPage> createState() => _RequisitionDetailPageState();
}

class _RequisitionDetailPageState extends State<RequisitionDetailPage> {
  // ---- พาเลตต์: กรมท่า / เทา (ชุดเดียวกับหน้าอื่น) ----
  static const _navy = Color(0xFF0F2A5C);
  static const _navyLight = Color(0xFF1D4190);
  static const _grayBg = Color(0xFFF1F5F9);
  static const _pageBg = Color(0xFFF5F7FA);
  static const _line = Color(0xFFE2E8F0);
  static const _divider = Color(0xFFEEF1F5);

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

  late Future<_Detail> _future;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _loadDetail();
    });
  }

  Future<_Detail> _loadDetail() async {
    final requisition = await RequisitionApi.detail(widget.requisitionId);

    List<StatusLog> logs = const [];

    if (widget.showTimeline) {
      try {
        logs = await RequisitionApi.statusLogs(widget.requisitionId);
      } catch (_) {
        logs = const [];
      }
    }

    return _Detail(requisition: requisition, logs: logs);
  }

  Future<void> _cancel() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'ยกเลิกใบเบิก',
      message: 'ต้องการยกเลิกใบเบิกนี้ใช่หรือไม่',
      confirmLabel: 'ยกเลิกใบเบิก',
      destructive: true,
    );

    if (!confirmed) return;

    setState(() => _cancelling = true);

    try {
      await RequisitionApi.cancel(widget.requisitionId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('ยกเลิกใบเบิกแล้ว'),
        ),
      );

      _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(errorMessageOf(e)),
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
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

  /// ไอคอนกรมท่าในกรอบสี่เหลี่ยมมนพื้นเทา
  Widget _iconTile(IconData icon, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _grayBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: _navy),
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconTile(icon, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// การ์ดหัวใบเบิก: แถบกรมท่าด้านบน (เลขที่ + สถานะ) + ช่องขาวด้านล่าง (รายละเอียด)
  Widget _headerCard(Requisition requisition, Widget statusChip) {
    final hasPurpose =
        requisition.purpose != null && requisition.purpose!.isNotEmpty;
    final hasDate = requisition.createdAt != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
        boxShadow: _shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // แถบหัวสีกรมท่า
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_navy, _navyLight],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'เลขที่ใบเบิก',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                        Text(
                          requisition.requestNo,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  statusChip,
                ],
              ),
            ),
            // ส่วนรายละเอียด
            if (hasPurpose || hasDate)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasPurpose)
                      _infoRow(
                        Icons.notes_rounded,
                        'วัตถุประสงค์',
                        requisition.purpose!,
                      ),
                    if (hasPurpose && hasDate)
                      const Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: Divider(height: 1, thickness: 1, color: _divider),
                      ),
                    if (hasDate)
                      _infoRow(
                        Icons.schedule_rounded,
                        'สร้างเมื่อ',
                        formatDateTime(requisition.createdAt!),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _itemsCard(Requisition requisition) {
    final items = requisition.items.toList();

    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _itemRow(items[i], i + 1),
            if (i != items.length - 1)
              const Divider(height: 1, thickness: 1, color: _divider),
          ],
        ],
      ),
    );
  }

  Widget _itemRow(dynamic item, int index) {
    final changed = item.approvedQuantity != item.requestedQuantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // เลขลำดับในกรอบเทา
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _grayBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _line),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                color: _navy,
                fontSize: 14,
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
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.ink,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ขอเบิก ${item.requestedQuantity} ${item.unit}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                if (changed)
                  Text(
                    'อนุมัติ ${item.approvedQuantity} ${item.unit}',
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(itemStatusStyle(item.status), small: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text(
          'รายละเอียดใบเบิก',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
        backgroundColor: _pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _line),
        ),
      ),
      body: FutureBuilder<_Detail>(
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

          final requisition = snapshot.data!.requisition;
          final logs = snapshot.data!.logs;
          final style = requisitionStatusStyle(requisition.status);

          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _headerCard(requisition, StatusChip(style)),
                if (requisition.adminComment?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  _card(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.admin_panel_settings_outlined, color: _navy),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'หมายเหตุจากแอดมิน',
                                style: TextStyle(fontWeight: FontWeight.w700, color: _navy),
                              ),
                              const SizedBox(height: 4),
                              Text(requisition.adminComment!.trim()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                if (widget.showTimeline) ...[
                  if (requisition.status == 'REJECTED' ||
                      requisition.status == 'CANCELLED')
                    RequisitionStatusBanner(status: requisition.status)
                  else ...[
                    _sectionTitle('ลำดับขั้นตอนการเบิก'),
                    const SizedBox(height: 12),
                    _card(
                      child: RequisitionTimeline(
                        currentStatus: requisition.status,
                        logs: logs,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                ],
                _sectionTitle(
                  'รายการวัสดุ',
                  trailing: '${requisition.items.length} รายการ',
                ),
                const SizedBox(height: 12),
                _itemsCard(requisition),
                if (requisition.canCancel) ...[
                  const SizedBox(height: 28),
                  SecondaryButton(
                    label: _cancelling ? 'กำลังยกเลิก...' : 'ยกเลิกใบเบิก',
                    onPressed: _cancelling ? null : _cancel,
                    icon: Icons.close_rounded,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Detail {
  final Requisition requisition;
  final List<StatusLog> logs;

  const _Detail({required this.requisition, required this.logs});
}
