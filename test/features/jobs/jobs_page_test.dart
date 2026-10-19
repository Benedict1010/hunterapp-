import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/app/job_scope.dart';
import 'package:hunter/app/resume_scope.dart';
import 'package:hunter/app/theme/app_theme.dart';
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/jobs/presentation/job_controller.dart';
import 'package:hunter/features/jobs/presentation/jobs_for_you_page.dart';
import 'package:hunter/features/resume/data/resume_service.dart';
import 'package:hunter/features/resume/domain/resume.dart';
import 'package:hunter/features/resume/domain/resume_version.dart';
import 'package:hunter/features/resume/presentation/resume_controller.dart';

import 'job_controller_test.dart';

class FakeResumeService implements ResumeService {
  @override
  final ApiClient apiClient = ApiClient(
    apiConfig: const ApiConfig(),
    tokenStorage: InMemoryTokenStorage(),
  );

  @override
  Future<List<Resume>> listResumes() async => [];

  @override
  Future<Resume> getResume(String id) async => throw UnimplementedError();

  @override
  Future<Resume> uploadResume({
    required String filePath,
    String? fileName,
    List<int>? bytes,
  }) async => throw UnimplementedError();

  @override
  Future<Resume> updateResume(
    String id, {
    required String filePath,
    String? fileName,
    List<int>? bytes,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteResume(String id) async {}

  @override
  Future<Resume> setPrimary(String id) async => throw UnimplementedError();

  @override
  Future<Resume> extractResume(String id) async => throw UnimplementedError();

  @override
  Future<List<ResumeVersion>> listVersions(String id) async => [];

  @override
  Future<ResumeVersion> getVersion(String id, String versionId) async =>
      throw UnimplementedError();

  @override
  Future<List<int>> downloadResume(String id) async => [];
}

void main() {
  testWidgets('JobsForYouPage displays jobs from controller', (tester) async {
    final fakeJobService = FakeJobService();
    final jobController = JobController(
      jobService: fakeJobService,
      initialJobs: fakeJobService.mockJobs,
    );
    final resumeController = ResumeController(
      resumeService: FakeResumeService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: JobScope(
          controller: jobController,
          child: ResumeScope(
            controller: resumeController,
            child: const JobsForYouPage(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Jobs For You'), findsOneWidget);
    expect(find.text('Flutter Engineer'), findsOneWidget);
    expect(find.text('AppCo'), findsOneWidget);
  });

  testWidgets('JobsForYouPage does not display salary filter Over \$120K', (
    tester,
  ) async {
    final fakeJobService = FakeJobService();
    final jobController = JobController(
      jobService: fakeJobService,
      initialJobs: fakeJobService.mockJobs,
    );
    final resumeController = ResumeController(
      resumeService: FakeResumeService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: JobScope(
          controller: jobController,
          child: ResumeScope(
            controller: resumeController,
            child: const JobsForYouPage(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Over \$120K'), findsNothing);
    expect(find.text('All Matches'), findsOneWidget);
    expect(find.text('Design'), findsOneWidget);
    expect(find.text('Remote'), findsOneWidget);
  });
}
