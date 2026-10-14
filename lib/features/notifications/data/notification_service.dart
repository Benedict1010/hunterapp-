import '../../../core/network/api_client.dart';
import '../domain/app_notification.dart';

class NotificationService {
  final ApiClient apiClient;

  NotificationService({required this.apiClient});

  Future<NotificationListResponse> listNotifications({
    int limit = 50,
    int offset = 0,
    bool? isRead,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (isRead != null) 'is_read': isRead.toString(),
    };

    final uri = Uri(path: '/notifications', queryParameters: queryParams);
    final response = await apiClient.get(uri.toString());
    return NotificationListResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<AppNotification> getNotification(String notificationId) async {
    final response = await apiClient.get('/notifications/$notificationId');
    return AppNotification.fromJson(response as Map<String, dynamic>);
  }

  Future<int> getUnreadCount() async {
    final response = await apiClient.get('/notifications/unread-count');
    final map = response as Map<String, dynamic>;
    return map['unread_count'] as int? ?? 0;
  }

  Future<AppNotification> markAsRead(String notificationId) async {
    final response = await apiClient.patch(
      '/notifications/$notificationId/read',
    );
    return AppNotification.fromJson(response as Map<String, dynamic>);
  }

  Future<int> markAllAsRead() async {
    final response = await apiClient.patch('/notifications/read-all');
    final map = response as Map<String, dynamic>;
    return map['updated_count'] as int? ?? 0;
  }

  Future<AppNotification> createNotification({
    required String title,
    required String message,
    String notificationType = 'general',
    String? relatedEntityType,
    String? relatedEntityId,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'message': message,
      'notification_type': notificationType,
      if (relatedEntityType != null && relatedEntityType.isNotEmpty)
        'related_entity_type': relatedEntityType,
      if (relatedEntityId != null && relatedEntityId.isNotEmpty)
        'related_entity_id': relatedEntityId,
    };

    final response = await apiClient.post('/notifications', body: body);
    return AppNotification.fromJson(response as Map<String, dynamic>);
  }
}
