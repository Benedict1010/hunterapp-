enum NotificationType { match, resume, application, opportunity, insight }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    this.actionLabel,
  });
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final String? actionLabel;
  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    time: time,
    isRead: isRead ?? this.isRead,
    actionLabel: actionLabel,
  );
}
