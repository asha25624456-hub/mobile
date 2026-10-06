import 'package:flutter/material.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/state_views.dart';
import '../../api/requisition_api.dart';
import '../../models/requisition.dart';
import '../../widgets/requisition_tile.dart';
import '../requisitions/requisition_detail_page.dart';

enum _HistoryFilter { all, completed, rejected }

const _monthNames = [
  '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
  'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
];

/// ชุดสีของใบเบิกแต่ละใบ แยกตามผลลัพธ์ (สำเร็จ / ถูกปฏิเสธ)
/// ใช้สีเฉพาะจุดเน้น (แถบข้าง + ป้ายสถานะ) พื้นการ์ดคงเป็นสีขาว
class _FrameTheme {
  final Color accent;
  final Color badgeBg;
  final Color border;
  final IconData icon;
  final String label;

  const _FrameTheme({
    required this.accent,
    required this.badgeBg,
    required this.border,
    required this.icon,
    required this.label,
  });

  static const done = _FrameTheme(
    accent: Color(0xFF15803D),
    badgeBg: Color(0xFFE8F6EE),
    border: Color(0xFFD7EBDF),
    icon: Icons.check_circle_rounded,
    label: 'สำเร็จแล้ว',
  );

  static const rejected = _FrameTheme(
    accent: Color(0xFFB91C1C),
    badgeBg: Color(0xFFFBEAEA),
    border: Color(0xFFF0D5D5),
    icon: Icons.cancel_rounded,
    label: 'ถูกปฏิเสธ',
  );
}

/// เนื้อหาแท็บย่อย "ประวัติการเบิก" ภายในหน้า ประวัติ & แจ้งเตือน
class RequisitionHistoryTab extends StatefulWidget {
  const RequisitionHistoryTab({super.key});

  @override
  State<RequisitionHistoryTab> createState() => _RequisitionHistoryTabState();
}

class _RequisitionHistoryTabState extends State<RequisitionHistoryTab> {
  // ---- ค่าสีเฉพาะหน้านี้ ----
  static const _pageBg = Color(0xFFF5F7FA);
  static const _navy = Color(0xFF0F2A5C);
  static const _navyLight = Color(0xFF1D4190);
  static const _ink = Color(0xFF0F172A);

  Future<List<Requisition>>? _future;
  _HistoryFilter _filter = _HistoryFilter.all;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = RequisitionApi.list();
    });
  }

  Future<void> _openDetail(Requisition requisition) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RequisitionDetailPage(
          requisitionId: requisition.id,
          showTimeline: false,
        ),
      ),
    );
    _load();
  }

  bool _matches(Requisition r, _HistoryFilter filter) {
    switch (filter) {
      case _HistoryFilter.all:
        return r.status == 'ISSUED' || r.status == 'REJECTED';
      case _HistoryFilter.completed:
        return r.status == 'ISSUED';
      case _HistoryFilter.rejected:
        return r.status == 'REJECTED';
    }
  }

  // ---- ส่วนประกอบ UI ----

  /// การ์ดสรุปรายเดือน: กรมท่าไล่สีนุ่ม + ลายเส้นบางตกแต่ง + แผ่นตัวเลข
  Widget _summaryCard({
    required String monthLabel,
    required List<DateTime> availableMonths,
    required int completedCount,
    required int completedQty,
  }) {
    Widget stat(IconData icon, String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 12.5,
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

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, _navyLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330F2A5C),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ลายเส้นวงแหวนบาง ให้ความรู้สึกเป็นทางการ
          Positioned(
            right: -50,
            top: -60,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            right: -10,
            top: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สรุปการเบิกประจำเดือน',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.96),
                              height: 1.4,
                            ),
                          ),
                          Text(
                            'เฉพาะรายการที่รับของเรียบร้อยแล้ว',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.65),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<DateTime>(
                      tooltip: 'เลือกเดือน',
                      onSelected: (month) =>
                          setState(() => _selectedMonth = month),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      itemBuilder: (context) => availableMonths
                          .map(
                            (month) => PopupMenuItem<DateTime>(
                              value: month,
                              child: Text(
                                '${_monthNames[month.month]} ${month.year + 543}',
                              ),
                            ),
                          )
                          .toList(),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                              color: _navy,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              monthLabel,
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: _navy,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    stat(
                      Icons.task_alt_rounded,
                      '$completedCount',
                      'คำขอสำเร็จ',
                    ),
                    const SizedBox(width: 12),
                    stat(
                      Icons.inventory_2_rounded,
                      '$completedQty',
                      'ชิ้นรวมทั้งหมด',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    List<Requisition> all,
    _HistoryFilter filter,
    String label,
  ) {
    final count = all.where((r) => _matches(r, filter)).length;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CategoryChip(
        label: '$label ($count)',
        selected: _filter == filter,
        onTap: () => setState(() => _filter = filter),
      ),
    );
  }

  String _dateLabel(DateTime? d) {
    if (d == null) return '';
    return '${d.day} ${_monthNames[d.month]} ${d.year + 543}';
  }

  /// หัวข้อส่วน พร้อมจำนวนรายการ
  Widget _sectionHeader(String title, int count) {
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _ink,
            height: 1.5,
          ),
        ),
        const Spacer(),
        Text(
          '$count รายการ',
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.muted,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// กรอบใบเบิก: พื้นขาวสะอาด แถบสีด้านซ้ายตามผลลัพธ์ + แถบหัวป้ายสถานะ/วันที่
  Widget _historyFrame(Requisition requisition) {
    final theme = requisition.status == 'ISSUED'
        ? _FrameTheme.done
        : _FrameTheme.rejected;

    final date = requisition.updatedAt ?? requisition.createdAt;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border),
        boxShadow: const [
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
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // แถบสีด้านซ้าย
              Container(width: 5, color: theme.accent),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                            decoration: BoxDecoration(
                              color: theme.badgeBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(theme.icon, size: 15, color: theme.accent),
                                const SizedBox(width: 5),
                                Text(
                                  theme.label,
                                  style: TextStyle(
                                    color: theme.accent,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (date != null) ...[
                            const Icon(
                              Icons.event_rounded,
                              size: 14,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _dateLabel(date),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            ),
                          ],
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

          final all = snapshot.data ?? [];
          // Completion is recorded when the admin confirms pickup, which updates
          // updated_at. created_at may belong to an earlier month for older requests.
          final completed = all
              .where((r) => r.status == 'ISSUED' && r.updatedAt != null)
              .toList();
          final monthKeys = <int>{
            DateTime.now().year * 12 + DateTime.now().month,
            for (final r in completed)
              r.updatedAt!.year * 12 + r.updatedAt!.month,
          }.toList()
            ..sort((a, b) => b.compareTo(a));
          final availableMonths = monthKeys
              .map((key) => DateTime((key - 1) ~/ 12, (key - 1) % 12 + 1))
              .toList();
          final selectedMonth = monthKeys.contains(
            _selectedMonth.year * 12 + _selectedMonth.month,
          )
              ? _selectedMonth
              : DateTime.now();
          final completedThisMonth = completed.where((r) =>
              r.updatedAt!.year == selectedMonth.year &&
              r.updatedAt!.month == selectedMonth.month);
          final completedQtyThisMonth = completedThisMonth.fold<int>(
            0,
            (sum, r) => sum + r.totalQuantity,
          );

          final filtered = all.where((r) => _matches(r, _filter)).toList();

          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                if (all.isNotEmpty) ...[
                  _summaryCard(
                    monthLabel:
                        '${_monthNames[selectedMonth.month]} ${selectedMonth.year + 543}',
                    availableMonths: availableMonths,
                    completedCount: completedThisMonth.length,
                    completedQty: completedQtyThisMonth,
                  ),
                  const SizedBox(height: 24),
                ],
                _sectionHeader('รายการใบเบิก', filtered.length),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      _filterChip(all, _HistoryFilter.all, 'ทั้งหมด'),
                      _filterChip(all, _HistoryFilter.completed, 'สำเร็จแล้ว'),
                      _filterChip(all, _HistoryFilter.rejected, 'ถูกปฏิเสธ'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyView(
                      icon: Icons.receipt_long_rounded,
                      title: 'ยังไม่มีใบเบิกในหมวดนี้',
                    ),
                  )
                else
                  for (final requisition in filtered) ...[
                    _historyFrame(requisition),
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