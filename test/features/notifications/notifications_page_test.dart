import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/app/notification_scope.dart';
import 'package:hunter/app/theme/app_theme.dart';
import 'package:hunter/features/notifications/presentation/notification_controller.dart';
import 'package:hunter/features/notifications/presentation/notifications_page.dart';

import 'notification_controller_test.dart';

void main() {
  testWidgets('NotificationsPage displays notifications from controller', (
    tester,
  ) async {
    final fakeService = FakeNotificationService();
    final controller = NotificationController(
      notificationService: fakeService,
      initialNotifications: fakeService.mockNotifs,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: NotificationScope(
          controller: controller,
          child: const NotificationsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('New Match'), findsOneWidget);
  });
}
