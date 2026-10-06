import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/brand_header.dart';
import '../api/notification_api.dart';
import 'cart/build_request_page.dart';
import 'history/history_notifications_page.dart';
import 'products/product_list_page.dart';
import 'profile/profile_page.dart';
import 'track/track_status_page.dart';

const _subtitles = [
  'ค้นหาและเบิกพัสดุ',
  'สร้างคำขอใหม่',
  'ติดตามสถานะ',
  'ประวัติและการแจ้งเตือน',
];

/// หน้าหลักฝั่งผู้เบิกวัสดุ: แถบบนแบรนด์ "SmartRequisition" + แถบล่าง 4 แท็บ
/// (ยังใช้ชื่อคลาส UserShell เดิมเพื่อไม่ต้องแก้ auth/auth_flow.dart)
class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  // ---- ค่าสีเฉพาะหน้านี้ ----
  static const _brand = Color(0xFF1E40AF);
  static const _brandSoft = Color(0xFFEFF6FF);
  static const _pageBg = Color(0xFFF8FAFC);
  static const _inactive = Color(0xFF94A3B8);

  int _index = 0;
  int _unreadCount = 0;

  // เพิ่มค่านี้เพื่อบังคับให้แท็บ "ประวัติ & แจ้งเตือน" สร้างใหม่และเปิดแท็บย่อยแจ้งเตือนทันที
  int _historySalt = 0;
  int _historyInitialSubTab = 0;

  // เพิ่มค่านี้เพื่อบังคับให้แท็บ "ติดตามสถานะ" สร้างใหม่และโหลดข้อมูลล่าสุด
  int _trackSalt = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final list = await NotificationApi.list();
      final unread = list.where((n) => !n.isRead).length;

      if (mounted) setState(() => _unreadCount = unread);
    } catch (_) {
      // จุดแดงบนกระดิ่งเป็นส่วนเสริม โหลดไม่สำเร็จก็ไม่ต้องรบกวนผู้ใช้
    }
  }

  void _goToTab(int index) {
    setState(() => _index = index);
  }

  void _openNotifications() {
    setState(() {
      _index = 3;
      _historySalt++;
      _historyInitialSubTab = 1;
    });
  }

  void _onRequisitionSubmitted(int? newId) {
    setState(() {
      _index = 2;
      _trackSalt++;
    });
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  // ---- ส่วนประกอบ UI ----

  PreferredSizeWidget _appBar() {
    return AppBar(
      titleSpacing: 20,
      toolbarHeight: 64,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: const Color(0x14000000),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: BrandTitle(subtitle: _subtitles[_index]),
      actions: [
        NotificationBellButton(
          unreadCount: _unreadCount,
          onTap: _openNotifications,
        ),
        const SizedBox(width: 4),
        ProfileAvatarButton(onTap: _openProfile),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _bottomBar() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 70,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: _brandSoft,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 24,
              color: selected ? _brand : _inactive,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              height: 1.5, // กันสระ/วรรณยุกต์ไทยถูกตัด
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? _brand : _inactive,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _goToTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded),
              label: 'พัสดุ',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_note_rounded),
              selectedIcon: Icon(Icons.edit_note_rounded),
              label: 'สร้างคำขอ',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping_rounded),
              label: 'ติดตาม',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'ประวัติ',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _appBar(),
      body: IndexedStack(
        index: _index,
        children: [
          ProductListPage(onGoToCart: () => _goToTab(1)),
          BuildRequestPage(
            onGoToProducts: () => _goToTab(0),
            onSubmitted: _onRequisitionSubmitted,
          ),
          TrackStatusPage(
            key: ValueKey('track-$_trackSalt'),
            onGoToProducts: () => _goToTab(0),
          ),
          HistoryNotificationsPage(
            key: ValueKey('history-$_historySalt'),
            initialSubTab: _historyInitialSubTab,
            onNotificationsViewed: () => setState(() => _unreadCount = 0),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }
}