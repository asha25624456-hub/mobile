import 'package:flutter/material.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../api/notification_api.dart';
import '../../models/app_notification.dart';
import '../../widgets/notification_tile.dart';
import '../requisitions/requisition_detail_page.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  // ---- ค่าสีเฉพาะหน้านี้ (ชุดเดียวกับหน้าอื่น) ----
  static const _brand = Color(0xFF1E40AF);
  static const _pageBg = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);

  Future<List<AppNotification>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = NotificationApi.list();
    });
  }

  /// กดแล้วเปิดดูได้ทุกรายการ
  /// - ใบขอเบิก: ไปหน้ารายละเอียด
  /// - อื่น ๆ: เปิด bottom sheet แสดงเนื้อหาเต็ม
  Future<void> _open(AppNotification notification) async {
    if (!notification.isRead) {
      NotificationApi.markRead(notification.id).catchError((_) {});
    }

    if (notification.referenceType == 'requisition' &&
        notification.referenceId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RequisitionDetailPage(
            requisitionId: notification.referenceId!,
          ),
        ),
      );
    } else {
      await _showDetail(notification);
    }

    if (mounted) _load();
  }

  Future<void> _showDetail(AppNotification notification) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                notification.message,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _brand),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ปิด'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- ส่วนประกอบ UI ----

  Widget _listHeader(int unreadCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'การแจ้งเตือนล่าสุด',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          if (unreadCount > 0)
            Text(
              'ยังไม่ได้อ่าน $unreadCount รายการ',
              style: const TextStyle(
                color: _brand,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  /// รวมการแจ้งเตือนทั้งหมดไว้ในการ์ดเดียว คั่นด้วยเส้นบาง
  Widget _groupedList(List<AppNotification> list) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < list.length; i++) ...[
            NotificationTile(
              notification: list[i],
              onTap: () => _open(list[i]),
            ),
            if (i != list.length - 1) const Divider(height: 1, color: _border),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _pageBg,
      child: FutureBuilder<List<AppNotification>>(
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
            return const EmptyView(
              icon: Icons.notifications_none,
              title: 'ยังไม่มีการแจ้งเตือน',
            );
          }

          final unreadCount = list.where((n) => !n.isRead).length;

          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView(
              // ให้ดึงรีเฟรชได้แม้รายการสั้น
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _listHeader(unreadCount),
                _groupedList(list),
              ],
            ),
          );
        },
      ),
    );
  }
}