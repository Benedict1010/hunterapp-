import 'package:flutter/widgets.dart';

import '../features/notifications/presentation/notification_controller.dart';

class NotificationScope extends InheritedNotifier<NotificationController> {
  const NotificationScope({
    required NotificationController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static NotificationController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<NotificationScope>();
    assert(scope != null, 'No NotificationScope found in context');
    return scope!.notifier!;
  }

  static NotificationController? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<NotificationScope>();
    return scope?.notifier;
  }
}
