import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/mock_notifications.dart';
import '../data/notification_service.dart';
import '../domain/app_notification.dart';

enum NotificationStateStatus { initial, loading, loaded, error }

class NotificationController extends ChangeNotifier {
  final NotificationService notificationService;

  NotificationStateStatus _status;
  List<AppNotification> _notifications;
  int _unreadCount;
  String? _errorMessage;

  NotificationController({
    required this.notificationService,
    List<AppNotification>? initialNotifications,
    NotificationStateStatus initialStatus = NotificationStateStatus.loaded,
  }) : _notifications = initialNotifications ?? List.of(mockNotificationsList),
       _status = initialStatus,
       _unreadCount = (initialNotifications ?? mockNotificationsList)
           .where((n) => !n.isRead)
           .length;

  NotificationStateStatus get status => _status;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == NotificationStateStatus.loading;
  bool get hasError => _status == NotificationStateStatus.error;

  void clearError() {
    _errorMessage = null;
    if (_status == NotificationStateStatus.error) {
      _status = NotificationStateStatus.loaded;
    }
    notifyListeners();
  }

  Future<void> loadNotifications({bool? isRead}) async {
    _status = NotificationStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await notificationService.apiClient.tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        _status = NotificationStateStatus.loaded;
        notifyListeners();
        return;
      }

      final response = await notificationService.listNotifications(
        isRead: isRead,
      );
      _notifications = response.items;
      _status = NotificationStateStatus.loaded;
      await fetchUnreadCount();
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = NotificationStateStatus.error;
    } catch (e) {
      _errorMessage = 'Failed to load notifications.';
      _status = NotificationStateStatus.error;
    }

    notifyListeners();
  }

  Future<void> fetchUnreadCount() async {
    try {
      final token = await notificationService.apiClient.tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
        return;
      }

      _unreadCount = await notificationService.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }

      final token = await notificationService.apiClient.tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        await notificationService.markAsRead(notificationId);
        await fetchUnreadCount();
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to mark notification as read.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      _notifications = [
        for (final item in _notifications) item.copyWith(isRead: true),
      ];
      _unreadCount = 0;
      notifyListeners();

      final token = await notificationService.apiClient.tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        await notificationService.markAllAsRead();
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to mark all notifications as read.';
      notifyListeners();
      return false;
    }
  }
}
