import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/app/application_scope.dart';
import 'package:hunter/app/job_scope.dart';
import 'package:hunter/app/resume_scope.dart';
import 'package:hunter/app/theme/app_theme.dart';
import 'package:hunter/features/applications/presentation/application_controller.dart';
import 'package:hunter/features/jobs/presentation/job_controller.dart';
import 'package:hunter/features/jobs/presentation/job_detail_page.dart';
import 'package:hunter/features/resume/presentation/resume_controller.dart';

import '../applications/application_controller_test.dart';
import 'job_controller_test.dart';
import 'jobs_page_test.dart';

void main() {
  group('JobDetailPage Tests', () {
    late FakeJobService fakeJobService;
    late JobController jobController;
    late FakeApplicationService fakeAppService;
    late ApplicationController appController;
    late ResumeController resumeController;

    setUp(() {
      fakeJobService = FakeJobService();
      jobController = JobController(
        jobService: fakeJobService,
        initialJobs: fakeJobService.mockJobs,
      );
      fakeAppService = FakeApplicationService();
      appController = ApplicationController(applicationService: fakeAppService);
      resumeController = ResumeController(resumeService: FakeResumeService());
    });

    Widget createWidgetToTest() {
      return MaterialApp(
        theme: AppTheme.light(),
        home: JobScope(
          controller: jobController,
          child: ResumeScope(
            controller: resumeController,
            child: ApplicationScope(
              controller: appController,
              child: const JobDetailPage(),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'Opening JobDetailPage records a job view for authenticated user',
      (tester) async {
        await tester.pumpWidget(createWidgetToTest());
        await tester.pumpAndSettle();

        expect(find.text('Flutter Engineer'), findsOneWidget);
        expect(find.textContaining('AppCo'), findsOneWidget);
        expect(fakeJobService.recordJobViewCallCount, 1);
        expect(jobController.isJobViewed('job-1'), isTrue);
      },
    );

    testWidgets(
      'Rebuilding JobDetailPage does not make duplicate view requests',
      (tester) async {
        await tester.pumpWidget(createWidgetToTest());
        await tester.pumpAndSettle();

        expect(fakeJobService.recordJobViewCallCount, 1);

        // Trigger rebuild
        await tester.pumpWidget(createWidgetToTest());
        await tester.pumpAndSettle();

        expect(fakeJobService.recordJobViewCallCount, 1);
      },
    );

    testWidgets(
      'Apply modal options work cleanly; external link does not create application',
      (tester) async {
        await tester.pumpWidget(createWidgetToTest());
        await tester.pumpAndSettle();

        final initialAppCount = fakeAppService.mockApps.length;

        // Tap "Apply Now"
        await tester.tap(find.text('Apply Now'));
        await tester.pumpAndSettle();

        expect(find.text('Apply to Flutter Engineer'), findsOneWidget);
        expect(find.text('Open External Application URL'), findsOneWidget);
        expect(find.text('Confirm & Track Application'), findsOneWidget);

        // Tap external application URL button
        await tester.tap(find.text('Open External Application URL'));
        await tester.pumpAndSettle();

        // Check no application created
        expect(fakeAppService.mockApps.length, equals(initialAppCount));
      },
    );
  });
}
