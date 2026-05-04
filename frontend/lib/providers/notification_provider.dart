import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  /// Call once after login to start receiving real-time notifications.
  void listenToSocket() {
    // Remove existing listener first to prevent duplicates on re-registration
    SocketService.off('notification');
    SocketService.on('notification', (data) {
      try {
        final notif = AppNotification.fromJson(data as Map<String, dynamic>);
        addRealtime(notif);
      } catch (_) {}
    });
  }

  /// Call on logout to stop listening.
  void stopListening() {
    SocketService.off('notification');
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await NotificationService.getNotifications();
      final fetched = result['notifications'] as List<AppNotification>;
      // Deduplicate: merge fetched with any realtime ones already in memory
      final existingIds = fetched.map((n) => n.id).toSet();
      final realtimeOnly = _notifications.where((n) => !existingIds.contains(n.id)).toList();
      _notifications = [...realtimeOnly, ...fetched];
      _unreadCount = _notifications.where((n) => !n.read).length;
    } catch (e) {
      _error = 'Failed to load notifications.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    try {
      await NotificationService.markRead(id);
      _notifications = _notifications
          .map((n) => n.id == id ? n.copyWith(read: true) : n)
          .toList();
      _unreadCount = _notifications.where((n) => !n.read).length;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await NotificationService.markAllRead();
      _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  void addRealtime(AppNotification notification) {
    // Avoid duplicates if the same notification arrives via socket and fetch
    if (_notifications.any((n) => n.id == notification.id)) return;
    _notifications = [notification, ..._notifications];
    if (!notification.read) _unreadCount++;
    notifyListeners();
  }
}
