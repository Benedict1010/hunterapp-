import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/notifications/data/notification_service.dart';

import '../../core/api_client_test.dart';

void main() {
  group('NotificationService Tests', () {
    late InMemoryTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage('test-token');
    });

    test(
      'listNotifications sends GET /notifications with limit/offset',
      () async {
        final mockClient = MockHttpClient((request) async {
          expect(request.url.path, equals('/notifications'));
          expect(request.url.queryParameters['limit'], equals('50'));

          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 'notif-1',
                  'user_id': 'u-1',
                  'notification_type': 'general',
                  'title': 'Welcome',
                  'message': 'Welcome to AI Job Hunter',
                  'is_read': false,
                  'created_at': '2026-03-20T10:00:00Z',
                  'updated_at': '2026-03-20T10:00:00Z',
                },
              ],
              'total': 1,
              'limit': 50,
              'offset': 0,
            }),
            200,
          );
        });

        final apiClient = ApiClient(
          apiConfig: const ApiConfig(),
          tokenStorage: tokenStorage,
          client: mockClient,
        );
        final service = NotificationService(apiClient: apiClient);

        final response = await service.listNotifications();

        expect(response.total, 1);
        expect(response.items.first.id, 'notif-1');
      },
    );

    test('getUnreadCount sends GET /notifications/unread-count', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, equals('/notifications/unread-count'));

        return http.Response(jsonEncode({'unread_count': 3}), 200);
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = NotificationService(apiClient: apiClient);

      final count = await service.getUnreadCount();

      expect(count, 3);
    });

    test('markAsRead sends PATCH /notifications/{id}/read', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('PATCH'));
        expect(request.url.path, equals('/notifications/notif-1/read'));

        return http.Response(
          jsonEncode({
            'id': 'notif-1',
            'user_id': 'u-1',
            'notification_type': 'general',
            'title': 'Welcome',
            'message': 'Welcome to AI Job Hunter',
            'is_read': true,
            'created_at': '2026-03-20T10:00:00Z',
            'updated_at': '2026-03-20T12:00:00Z',
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = NotificationService(apiClient: apiClient);

      final updated = await service.markAsRead('notif-1');

      expect(updated.isRead, isTrue);
    });

    test('markAllAsRead sends PATCH /notifications/read-all', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('PATCH'));
        expect(request.url.path, equals('/notifications/read-all'));

        return http.Response(jsonEncode({'updated_count': 5}), 200);
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = NotificationService(apiClient: apiClient);

      final count = await service.markAllAsRead();

      expect(count, 5);
    });
  });
}
