import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/features/notifications/domain/app_notification.dart';

void main() {
  group('AppNotification Model Tests', () {
    test('AppNotification parses correctly from JSON', () {
      final json = {
        'id': 'notif-1',
        'user_id': 'usr-1',
        'notification_type': 'application_status_changed',
        'title': 'Status Changed',
        'message': 'Your application to Tech Corp moved to Interview',
        'is_read': false,
        'related_entity_type': 'application',
        'related_entity_id': 'app-123',
        'created_at': '2026-03-20T10:00:00Z',
        'updated_at': '2026-03-20T10:00:00Z',
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 'notif-1');
      expect(notif.userId, 'usr-1');
      expect(notif.type, NotificationType.application);
      expect(notif.title, 'Status Changed');
      expect(notif.isRead, isFalse);
      expect(notif.relatedEntityType, 'application');
      expect(notif.relatedEntityId, 'app-123');

      final toJson = notif.toJson();
      expect(toJson['id'], 'notif-1');
      expect(toJson['is_read'], false);
    });

    test('NotificationListResponse parses list correctly', () {
      final json = {
        'items': [
          {
            'id': 'n1',
            'user_id': 'u1',
            'notification_type': 'match',
            'title': 'New Match',
            'message': '95% match found',
            'is_read': false,
            'created_at': '2026-03-20T10:00:00Z',
            'updated_at': '2026-03-20T10:00:00Z',
          },
        ],
        'total': 1,
        'limit': 50,
        'offset': 0,
      };

      final response = NotificationListResponse.fromJson(json);

      expect(response.items.length, 1);
      expect(response.total, 1);
      expect(response.items.first.id, 'n1');
    });
  });
}
