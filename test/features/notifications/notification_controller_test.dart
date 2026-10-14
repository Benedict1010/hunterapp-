import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/network/api_exception.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/notifications/data/notification_service.dart';
import 'package:hunter/features/notifications/domain/app_notification.dart';
import 'package:hunter/features/notifications/presentation/notification_controller.dart';

class FakeNotificationService implements NotificationService {
  bool shouldFail = false;

  @override
  final ApiClient apiClient = ApiClient(
    apiConfig: const ApiConfig(),
    tokenStorage: InMemoryTokenStorage('test-token'),
  );

  List<AppNotification> mockNotifs = [
    AppNotification(
      id: 'n1',
      userId: 'u1',
      type: NotificationType.match,
      rawNotificationType: 'match',
      title: 'New Match',
      message: 'Found match',
      isRead: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<NotificationListResponse> listNotifications({
    int limit = 50,
    int offset = 0,
    bool? isRead,
  }) async {
    if (shouldFail) {
      throw const ApiException(
        type: ApiErrorType.serverError,
        message: 'Failed to list notifications',
        statusCode: 500,
      );
    }
    return NotificationListResponse(
      items: mockNotifs,
      total: mockNotifs.length,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<AppNotification> getNotification(String notificationId) async {
    return mockNotifs.firstWhere((n) => n.id == notificationId);
  }

  @override
  Future<int> getUnreadCount() async {
    return mockNotifs.where((n) => !n.isRead).length;
  }

  @override
  Future<AppNotification> markAsRead(String notificationId) async {
    if (shouldFail) {
      throw const ApiException(
        type: ApiErrorType.serverError,
        message: 'Mark as read failed',
        statusCode: 500,
      );
    }
    final existing = mockNotifs.firstWhere((n) => n.id == notificationId);
    return existing.copyWith(isRead: true);
  }

  @override
  Future<int> markAllAsRead() async {
    if (shouldFail) {
      throw const ApiException(
        type: ApiErrorType.serverError,
        message: 'Mark all as read failed',
        statusCode: 500,
      );
    }
    final count = mockNotifs.where((n) => !n.isRead).length;
    mockNotifs = [for (final n in mockNotifs) n.copyWith(isRead: true)];
    return count;
  }

  @override
  Future<AppNotification> createNotification({
    required String title,
    required String message,
    String notificationType = 'general',
    String? relatedEntityType,
    String? relatedEntityId,
  }) async {
    final newN = AppNotification(
      id: 'n-new',
      userId: 'u1',
      type: NotificationType.general,
      rawNotificationType: notificationType,
      title: title,
      message: message,
      isRead: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    mockNotifs.add(newN);
    return newN;
  }
}

void main() {
  group('NotificationController Tests', () {
    late FakeNotificationService fakeService;
    late NotificationController controller;

    setUp(() {
      fakeService = FakeNotificationService();
      controller = NotificationController(
        notificationService: fakeService,
        initialNotifications: [],
        initialStatus: NotificationStateStatus.initial,
      );
    });

    test('Initial state is idle/initial', () {
      expect(controller.status, NotificationStateStatus.initial);
      expect(controller.notifications, isEmpty);
      expect(controller.unreadCount, 0);
    });

    test('loadNotifications populates notifications', () async {
      await controller.loadNotifications();

      expect(controller.status, NotificationStateStatus.loaded);
      expect(controller.notifications.length, 1);
      expect(controller.unreadCount, 1);
    });

    test('markAsRead updates notification state', () async {
      await controller.loadNotifications();

      final success = await controller.markAsRead('n1');

      expect(success, isTrue);
      expect(controller.notifications.first.isRead, isTrue);
      expect(controller.unreadCount, 0);
    });

    test('markAllAsRead marks all notifications read', () async {
      await controller.loadNotifications();

      final success = await controller.markAllAsRead();

      expect(success, isTrue);
      expect(controller.unreadCount, 0);
      expect(controller.notifications.every((n) => n.isRead), isTrue);
    });
  });
}
