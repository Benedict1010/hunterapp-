import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/app/application_scope.dart';
import 'package:hunter/app/theme/app_theme.dart';
import 'package:hunter/features/applications/presentation/application_controller.dart';
import 'package:hunter/features/applications/presentation/applications_page.dart';

import 'application_controller_test.dart';

void main() {
  testWidgets('ApplicationsPage displays applications from controller', (
    tester,
  ) async {
    final fakeService = FakeApplicationService();
    final controller = ApplicationController(
      applicationService: fakeService,
      initialApplications: fakeService.mockApps,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ApplicationScope(
          controller: controller,
          child: const ApplicationsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Applications'), findsOneWidget);
    expect(find.text('Senior Software Engineer'), findsOneWidget);
    expect(find.text('ABC Technologies'), findsOneWidget);
  });
}
