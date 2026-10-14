enum NotificationType {
  match,
  resume,
  application,
  opportunity,
  insight,
  general;

  static NotificationType fromString(String type) {
    switch (type.toLowerCase().trim()) {
      case 'match':
        return NotificationType.match;
      case 'resume':
        return NotificationType.resume;
      case 'application':
      case 'application_status_changed':
        return NotificationType.application;
      case 'opportunity':
        return NotificationType.opportunity;
      case 'insight':
        return NotificationType.insight;
      default:
        return NotificationType.general;
    }
  }
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String rawNotificationType;
  final String title;
  final String message;
  final bool isRead;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? actionLabel;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.rawNotificationType,
    required this.title,
    required this.message,
    required this.isRead,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.createdAt,
    required this.updatedAt,
    this.actionLabel,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawType = json['notification_type'] as String? ?? 'general';
    final parsedType = NotificationType.fromString(rawType);
    return AppNotification(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: parsedType,
      rawNotificationType: rawType,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      relatedEntityType: json['related_entity_type'] as String?,
      relatedEntityId: json['related_entity_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      actionLabel:
          json['action_label'] as String? ??
          (parsedType == NotificationType.application ? 'View Details' : null),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'notification_type': rawNotificationType,
    'title': title,
    'message': message,
    'is_read': isRead,
    'related_entity_type': relatedEntityType,
    'related_entity_id': relatedEntityId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  AppNotification copyWith({bool? isRead, String? title, String? message}) =>
      AppNotification(
        id: id,
        userId: userId,
        type: type,
        rawNotificationType: rawNotificationType,
        title: title ?? this.title,
        message: message ?? this.message,
        isRead: isRead ?? this.isRead,
        relatedEntityType: relatedEntityType,
        relatedEntityId: relatedEntityId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        actionLabel: actionLabel,
      );

  String get time {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class NotificationListResponse {
  final List<AppNotification> items;
  final int total;
  final int limit;
  final int offset;

  const NotificationListResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) =>
                    AppNotification.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 50,
      offset: json['offset'] as int? ?? 0,
    );
  }
}
