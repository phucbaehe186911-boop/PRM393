import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../services/firestore_service.dart';

/// ViewModel quản lý thông báo trong app
class NotificationViewModel extends ChangeNotifier {
  final FirestoreService _db;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;

  NotificationViewModel(this._db);

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  // ─── Load ──────────────────────────────────────────────────────────────────

  /// Tải thông báo của user từ DB
  Future<void> loadNotifications(int userId) async {
    try {
      _notifications = await _db.getNotificationsByUser(userId);
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationViewModel.loadNotifications error: $e');
    }
  }

  // ─── Mark read ─────────────────────────────────────────────────────────────

  /// Đánh dấu một thông báo đã đọc
  Future<void> markRead(int notifId) async {
    await _db.markNotificationRead(notifId);
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }
  }

  /// Đánh dấu tất cả đã đọc
  Future<void> markAllRead(int userId) async {
    await _db.markAllNotificationsRead(userId);
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();
  }

  // ─── Create ────────────────────────────────────────────────────────────────

  /// Tạo thông báo mới (gọi từ BookingViewModel)
  Future<void> createNotification({
    required int userId,
    required String title,
    required String body,
    required String type,
    int? bookingId,
  }) async {
    final notif = AppNotification(
      id: 0,
      userId: userId,
      title: title,
      body: body,
      type: type,
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
      bookingId: bookingId,
    );
    final id = await _db.insertNotification(notif);
    final savedNotif = notif.copyWith(id: id);
    _notifications.insert(0, savedNotif);
    _unreadCount++;
    notifyListeners();
  }
}
