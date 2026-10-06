import '../../core/api/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../models/app_notification.dart';

/// backend/user/read_notifications.php, mark_notification_read.php
class NotificationApi {
  NotificationApi._();

  static Future<List<AppNotification>> list() async {
    final data = await ApiClient.post(
      'user/read_notifications.php',
      auth: true,
    );

    return asMapList(data['data']).map(AppNotification.fromJson).toList();
  }

  static Future<void> markRead(int id) async {
    await ApiClient.post(
      'user/mark_notification_read.php',
      auth: true,
      body: {'id': id.toString()},
    );
  }
}
