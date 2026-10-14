import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/network/api_exception.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/applications/data/application_service.dart';
import 'package:hunter/features/applications/domain/job_application.dart';
import 'package:hunter/features/applications/presentation/application_controller.dart';

class FakeApplicationService implements ApplicationService {
  bool shouldFail = false;

  @override
  final ApiClient apiClient = ApiClient(
    apiConfig: const ApiConfig(),
    tokenStorage: InMemoryTokenStorage('test-token'),
  );

  List<Application> mockApps = [
    Application(
      id: 'app-1',
      userId: 'u-1',
      jobId: 'j-1',
      resumeVersionId: 'ver-1',
      status: ApplicationStatus.applied,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      job: const JobSummary(
        id: 'j-1',
        title: 'Senior Software Engineer',
        company: 'ABC Technologies',
      ),
    ),
  ];

  ApplicationTimelineEvent mockEvent = ApplicationTimelineEvent(
    id: 'tm-1',
    applicationId: 'app-1',
    status: ApplicationStatus.applied,
    note: 'Initial note',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  Future<List<Application>> listApplications({
    ApplicationStatus? status,
  }) async {
    if (shouldFail) {
      throw const ApiException(
        type: ApiErrorType.serverError,
        message: 'Failed to list applications',
        statusCode: 500,
      );
    }
    return mockApps;
  }

  @override
  Future<Application> getApplication(String applicationId) async {
    if (shouldFail) {
      throw const ApiException(
        type: ApiErrorType.notFound,
        message: 'Application not found',
        statusCode: 404,
      );
    }
    return mockApps.firstWhere((a) => a.id == applicationId);
  }

  @override
  Future<ApplicationExternalLink> getExternalLink(String applicationId) async {
    return ApplicationExternalLink(
      applicationId: applicationId,
      applicationUrl: 'https://example.com/apply',
    );
  }

  @override
  Future<Application> createApplication({
    required String jobId,
    required String resumeVersionId,
    String? applicationUrl,
    String? source,
    ApplicationStatus status = ApplicationStatus.applied,
    DateTime? appliedAt,
  }) async {
    if (shouldFail) {
      throw const ApiException(
        type: ApiErrorType.badRequest,
        message: 'Create application failed',
        statusCode: 400,
      );
    }
    final newApp = Application(
      id: 'app-new',
      userId: 'u-1',
      jobId: jobId,
      resumeVersionId: resumeVersionId,
      status: status,
      applicationUrl: applicationUrl,
      source: source,
      appliedAt: appliedAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    mockApps.add(newApp);
    return newApp;
  }

  @override
  Future<Application> updateApplicationStatus(
    String applicationId,
    ApplicationStatus status, {
    String? applicationUrl,
    String? source,
    DateTime? appliedAt,
  }) async {
    if (shouldFail) {
      throw const ApiException(
        type: ApiErrorType.serverError,
        message: 'Update status failed',
        statusCode: 500,
      );
    }
    final existing = mockApps.firstWhere((a) => a.id == applicationId);
    final updated = Application(
      id: existing.id,
      userId: existing.userId,
      jobId: existing.jobId,
      resumeVersionId: existing.resumeVersionId,
      status: status,
      applicationUrl: applicationUrl ?? existing.applicationUrl,
      source: source ?? existing.source,
      appliedAt: appliedAt ?? existing.appliedAt,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      job: existing.job,
    );
    return updated;
  }

  @override
  Future<List<ApplicationTimelineEvent>> listTimeline(
    String applicationId,
  ) async {
    return [mockEvent];
  }

  @override
  Future<ApplicationTimelineEvent> getTimelineEvent(
    String applicationId,
    String timelineId,
  ) async {
    return mockEvent;
  }

  @override
  Future<ApplicationTimelineEvent> addTimelineEvent(
    String applicationId,
    ApplicationStatus status, {
    String? note,
  }) async {
    return ApplicationTimelineEvent(
      id: 'tm-2',
      applicationId: applicationId,
      status: status,
      note: note,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  group('ApplicationController Tests', () {
    late FakeApplicationService fakeService;
    late ApplicationController controller;

    setUp(() {
      fakeService = FakeApplicationService();
      controller = ApplicationController(
        applicationService: fakeService,
        initialApplications: [],
        initialStatus: ApplicationStateStatus.initial,
      );
    });

    test('Initial state is idle/initial', () {
      expect(controller.status, ApplicationStateStatus.initial);
      expect(controller.applications, isEmpty);
      expect(controller.selectedApplication, isNull);
    });

    test('loadApplications populates applications on success', () async {
      await controller.loadApplications();

      expect(controller.status, ApplicationStateStatus.loaded);
      expect(controller.applications.length, 1);
      expect(controller.applications.first.id, 'app-1');
    });

    test('loadApplications handles failure', () async {
      fakeService.shouldFail = true;

      await controller.loadApplications();

      expect(controller.status, ApplicationStateStatus.error);
      expect(controller.hasError, isTrue);
    });

    test('createApplication adds new application to list', () async {
      final newApp = await controller.createApplication(
        jobId: 'j-2',
        resumeVersionId: 'ver-2',
      );

      expect(newApp, isNotNull);
      expect(newApp?.id, 'app-new');
      expect(controller.selectedApplication?.id, 'app-new');
    });

    test('updateApplicationStatus updates application state', () async {
      await controller.loadApplications();

      final updated = await controller.updateApplicationStatus(
        'app-1',
        ApplicationStatus.interview,
      );

      expect(updated, isNotNull);
      expect(updated?.status, ApplicationStatus.interview);
    });
  });
}
