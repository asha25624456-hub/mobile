import 'package:flutter/material.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/state_views.dart';
import '../../api/requisition_api.dart';
import '../../models/requisition.dart';
import '../../widgets/requisition_tile.dart';
import '../requisitions/requisition_detail_page.dart';

const _activeStatuses = {
  'PENDING', 'APPROVED',
};

/// แท็บ "ติดตามสถานะ": แสดงเฉพาะใบเบิกที่ยังไม่จบ (ไม่รวมเสร็จสิ้น/ปฏิเสธ/ยกเลิก)
class TrackStatusPage extends StatefulWidget {
  final VoidCallback onGoToProducts;

  const TrackStatusPage({super.key, required this.onGoToProducts});

  @override
  State<TrackStatusPage> createState() => _TrackStatusPageState();
}

class _TrackStatusPageState extends State<TrackStatusPage> {
  // ---- พาเลตต์: กรมท่า / เหลือง (รออนุมัติ) / เขียว (อนุมัติแล้ว) / เทา ----
  static const _navy = Color(0xFF0F2A5C);
  static const _grayBg = Color(0xFFF1F5F9);
  static const _pageBg = Color(0xFFF5F7FA);
  static const _line = Color(0xFFE2E8F0);

  // เหลือง: รออนุมัติ
  static const _yellow = Color(0xFFEAB308);
  static const _yellowSoft = Color(0xFFFEF6D8);
  static const _yellowBorder = Color(0xFFF3E4A6);
  static const _yellowText = Color(0xFF854D0E);

  // เขียว: อนุมัติแล้ว
  static const _green = Color(0xFF16A34A);
  static const _greenSoft = Color(0xFFE4F5EA);
  static const _greenBorder = Color(0xFFBFE5CC);
  static const _greenText = Color(0xFF166534);

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

  Future<List<Requisition>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = RequisitionApi.list().then(
        (list) => list.where((r) => _activeStatuses.contains(r.status)).toList(),
      );
    });
  }

  Future<void> _openDetail(Requisition requisition) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RequisitionDetailPage(requisitionId: requisition.id),
      ),
    );
    _load();
  }

  // ---- ส่วนประกอบ UI ----

  bool _isApproved(String status) => status == 'APPROVED';

  Color _accentOf(String status) => _isApproved(status) ? _green : _yellow;

  Color _softOf(String status) =>
      _isApproved(status) ? _greenSoft : _yellowSoft;

  Color _borderOf(String status) =>
      _isApproved(status) ? _greenBorder : _yellowBorder;

  Color _textOf(String status) =>
      _isApproved(status) ? _greenText : _yellowText;

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: _grayBg,
                shape: BoxShape.circle,
                border: Border.all(color: _line),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.local_shipping_rounded,
                size: 38,
                color: _navy,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ยังไม่มีคำขอที่กำลังดำเนินการ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'สร้างคำขอเบิกใหม่แล้วจะตามสถานะได้ที่นี่',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SecondaryButton(
              label: 'ไปเลือกพัสดุ',
              icon: Icons.inventory_2_outlined,
              onPressed: widget.onGoToProducts,
            ),
          ],
        ),
      ),
    );
  }

  /// การ์ดสรุปจำนวน: พื้นขาว ขอบบาง ไอคอนกรมท่าบนพื้นเทา (ไม่ใช้สีสถานะ)
  Widget _statTile({
    required IconData icon,
    required int count,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line),
          boxShadow: _shadows,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _grayBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 21, color: _navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(List<Requisition> list) {
    final pending = list.where((r) => r.status != 'APPROVED').length;
    final approved = list.where((r) => r.status == 'APPROVED').length;

    return Row(
      children: [
        _statTile(
          icon: Icons.hourglass_top_rounded,
          count: pending,
          label: 'รออนุมัติ',
        ),
        const SizedBox(width: 12),
        _statTile(
          icon: Icons.check_circle_outline_rounded,
          count: approved,
          label: 'อนุมัติแล้ว',
        ),
      ],
    );
  }

  Widget _listHeader(int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
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
          const Expanded(
            child: Text(
              'คำขอที่กำลังดำเนินการ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
          ),
          Text(
            '$count รายการ',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// ป้ายสถานะแบบแคปซูล: เหลือง = รออนุมัติ, เขียว = อนุมัติแล้ว
  Widget _statusBadge(String status) {
    final approved = _isApproved(status);
    final text = _textOf(status);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: _softOf(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            approved
                ? Icons.check_circle_rounded
                : Icons.hourglass_top_rounded,
            size: 15,
            color: text,
          ),
          const SizedBox(width: 5),
          Text(
            approved ? 'อนุมัติแล้ว' : 'รออนุมัติ',
            style: TextStyle(
              color: text,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// กรอบใบเบิก: การ์ดขาว ขอบ/แถบข้าง/ป้ายสถานะ เปลี่ยนสีตามสถานะ
  Widget _requisitionFrame(Requisition requisition) {
    final status = requisition.status;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderOf(status)),
        boxShadow: _shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: _accentOf(status)),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      child: Row(
                        children: [
                          _statusBadge(status),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEEF1F5),
                    ),
                    RequisitionTile(
                      requisition: requisition,
                      onTap: () => _openDetail(requisition),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _pageBg,
      child: FutureBuilder<List<Requisition>>(
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

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return _emptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                _summaryRow(list),
                const SizedBox(height: 28),
                _listHeader(list.length),
                for (final requisition in list) ...[
                  _requisitionFrame(requisition),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}