import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/app/app.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/resume/data/resume_service.dart';
import 'package:hunter/features/resume/presentation/resume_controller.dart';

void main() {
  Widget buildTestApp() {
    final tokenStorage = InMemoryTokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final resumeService = ResumeService(apiClient: apiClient);
    final resumeController = ResumeController(resumeService: resumeService);
    return AiJobHunterApp(resumeController: resumeController);
  }

  testWidgets('landing starts the supplied onboarding flow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildTestApp());
    expect(find.text('Your AI Job Search,'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Get Started'), 300);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Resume Verified'), findsOneWidget);
  });

  testWidgets('implemented dashboard and job routes render supplied content', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildTestApp());

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/home');
    await tester.pumpAndSettle();
    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('Benedict'), findsOneWidget);

    navigator.pushNamed('/jobs');
    await tester.pumpAndSettle();
    expect(find.text('Jobs For You'), findsOneWidget);
    expect(find.text('Senior Product'), findsOneWidget);

    navigator.pushNamed('/job-detail');
    await tester.pumpAndSettle();
    expect(find.text('Software Engineer Intern'), findsOneWidget);
    expect(find.text('AI Skill Analysis'), findsOneWidget);

    navigator.pushNamed('/optimization-ready');
    await tester.pumpAndSettle();
    expect(find.text('Optimization Ready'), findsOneWidget);

    navigator.pushNamed('/tailored-resume');
    await tester.pumpAndSettle();
    expect(find.text('AI Tailored Optimization'), findsOneWidget);

    navigator.pushNamed('/applications');
    await tester.pumpAndSettle();
    expect(find.text('Applications'), findsOneWidget);
  });

  testWidgets('phase 2E routes render local UI screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildTestApp());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    navigator.pushNamed('/application-details');
    await tester.pumpAndSettle();
    expect(find.text('HIRING PROCESS'), findsOneWidget);

    navigator.pushNamed('/notifications');
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);

    navigator.pushNamed('/profile');
    await tester.pumpAndSettle();
    expect(find.text('Account Profile'), findsOneWidget);

    navigator.pushNamed('/settings');
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });
}
