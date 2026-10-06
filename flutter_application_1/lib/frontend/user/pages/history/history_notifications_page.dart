import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../notifications/notification_list_page.dart';
import 'requisition_history_tab.dart';

/// แท็บ "ประวัติ & แจ้งเตือน": รวมประวัติการเบิก และการแจ้งเตือน ไว้ในแท็บย่อยเดียวกัน
///
/// เปิดแท็บย่อย "การแจ้งเตือน" ตั้งแต่แรกได้ด้วย [initialSubTab] = 1
/// (ใช้ตอนกดกระดิ่งแจ้งเตือนจากหน้าอื่น — เปลี่ยน key ของ widget นี้ให้ต่างไปจากเดิม
/// เพื่อบังคับให้สร้างใหม่พร้อมค่านี้ แม้ตัว widget จะถูกเก็บสถานะไว้ใน IndexedStack ก็ตาม)
class HistoryNotificationsPage extends StatefulWidget {
  /// เรียกทุกครั้งที่แท็บย่อย "การแจ้งเตือน" ถูกเปิดดู (ให้หน้าหลักอัปเดตจำนวนที่ยังไม่อ่าน)
  final VoidCallback onNotificationsViewed;
  final int initialSubTab;

  const HistoryNotificationsPage({
    super.key,
    required this.onNotificationsViewed,
    this.initialSubTab = 0,
  });

  @override
  State<HistoryNotificationsPage> createState() => _HistoryNotificationsPageState();
}

class _HistoryNotificationsPageState extends State<HistoryNotificationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialSubTab,
    );
    _tabController.addListener(_onTabChanged);

    if (widget.initialSubTab == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onNotificationsViewed());
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 1) {
      widget.onNotificationsViewed();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppColors.ink,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.ink,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          tabs: const [
            Tab(text: 'ประวัติการเบิก'),
            Tab(text: 'การแจ้งเตือน'),
          ],
        ),
        const Divider(height: 1, color: AppColors.line),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              RequisitionHistoryTab(),
              NotificationListPage(),
            ],
          ),
        ),
      ],
    );
  }
}
