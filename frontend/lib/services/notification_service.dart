import '../config/api_config.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService {
  static Future<Map<String, dynamic>> getNotifications() async {
    final data = await ApiService.get(ApiConfig.notifications, auth: true);
    final notifications = (data['notifications'] as List? ?? [])
        .map((json) => AppNotification.fromJson(json))
        .toList();
    return {
      'notifications': notifications,
      'unreadCount': data['unreadCount'] ?? 0,
    };
  }

  static Future<void> markRead(String id) async {
    await ApiService.patch(ApiConfig.notificationMarkRead(id), auth: true);
  }

  static Future<void> markAllRead() async {
    await ApiService.patch(ApiConfig.notificationsMarkAllRead, auth: true);
  }
}
