import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/network/api_exception.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/jobs/data/job_service.dart';
import 'package:hunter/features/jobs/domain/ai_analysis.dart';
import 'package:hunter/features/jobs/domain/ai_tailoring.dart';
import 'package:hunter/features/jobs/domain/job.dart';
import 'package:hunter/features/jobs/domain/job_match.dart';
import 'package:hunter/features/jobs/domain/job_view.dart';
import 'package:hunter/features/jobs/presentation/job_controller.dart';

class FakeJobService implements JobService {
  bool shouldFail = false;
  bool? lastUseSavedPreferences;
  int createMatchCallCount = 0;
  int listViewedJobsCallCount = 0;
  int recordJobViewCallCount = 0;
  bool shouldFailViewRequest = false;
  List<JobView> persistedViews = [];

  @override
  final ApiClient apiClient = ApiClient(
    apiConfig: const ApiConfig(),
    tokenStorage: InMemoryTokenStorage('test'),
  );

  List<Job> mockJobs = [
    const Job(
      id: 'job-1',
      title: 'Flutter Engineer',
      company: 'AppCo',
      externalUrl: 'https://appco.com',
      source: 'LinkedIn',
    ),
  ];

  JobMatch mockMatch = JobMatch(
    id: 'm1',
    userId: 'u1',
    resumeId: 'r1',
    jobId: 'job-1',
    matchScore: 90.0,
    matchedSkills: ['Flutter'],
    missingSkills: [],
    explanation: 'Great match!',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  AiAnalysis mockAnalysis = const AiAnalysis(
    summary: 'Great fit',
    strengths: ['Flutter'],
    missingSkills: [],
    recommendations: ['Keep coding'],
  );

  AiTailoring mockTailoring = const AiTailoring(
    tailoredResume: 'Tailored Flutter resume',
    changesMade: ['Refined summary'],
    warnings: [],
  );

  @override
  Future<JobListResponse> listJobs({
    String? company,
    String? location,
    String? jobType,
    bool? useSavedPreferences,
    int limit = 20,
    int offset = 0,
  }) async {
    lastUseSavedPreferences = useSavedPreferences;
    if (shouldFail) {
      throw const ApiException(
        type: ApiErrorType.serverError,
        message: 'Failed to load jobs',
        statusCode: 500,
      );
    }
    return JobListResponse(
      items: mockJobs,
      total: mockJobs.length,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<Job> getJob(String jobId) async {
    if (shouldFail) {
      throw const ApiException(
        type: ApiErrorType.notFound,
        message: 'Job not found',
        statusCode: 404,
      );
    }
    return mockJobs.firstWhere((j) => j.id == jobId);
  }

  @override
  Future<List<JobView>> listViewedJobs() async {
    listViewedJobsCallCount++;
    return persistedViews;
  }

  @override
  Future<JobView> recordJobView(String jobId) async {
    recordJobViewCallCount++;
    if (shouldFailViewRequest) {
      throw const ApiException(
        type: ApiErrorType.serverError,
        message: 'View recording failed',
        statusCode: 500,
      );
    }
    final view = JobView(
      id: 'view-$jobId',
      userId: 'u1',
      jobId: jobId,
      createdAt: DateTime.now(),
    );
    persistedViews = [...persistedViews, view];
    return view;
  }

  @override
  Future<JobMatch> createOrGetMatch({
    required String jobId,
    required String resumeId,
  }) async {
    createMatchCallCount++;
    if (shouldFail) {
      throw const ApiException(
        type: ApiErrorType.badRequest,
        message: 'Matching failed',
        statusCode: 400,
      );
    }
    return JobMatch(
      id: 'm_$jobId',
      userId: 'u1',
      resumeId: resumeId,
      jobId: jobId,
      matchScore: mockMatch.matchScore,
      matchedSkills: mockMatch.matchedSkills,
      missingSkills: mockMatch.missingSkills,
      explanation: mockMatch.explanation,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<JobMatch>> listMatches() async {
    if (shouldFail) {
      throw const ApiException(
        type: ApiErrorType.serverError,
        message: 'List matches failed',
        statusCode: 500,
      );
    }
    return [
      mockMatch,
      JobMatch(
        id: 'm2',
        userId: 'u1',
        resumeId: 'r2_non_primary',
        jobId: 'job-2',
        matchScore: 85.0,
        matchedSkills: ['Dart'],
        missingSkills: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<JobMatch> getMatch(String matchId) async {
    return mockMatch;
  }

  @override
  Future<AiAnalysis> analyzeJobMatch({
    required String jobId,
    required String resumeId,
  }) async {
    if (shouldFail) {
      throw const ApiException(
        type: ApiErrorType.serverError,
        message: 'AI analysis failed',
        statusCode: 500,
      );
    }
    return mockAnalysis;
  }

  @override
  Future<AiTailoring> tailorResume({
    required String jobId,
    required String resumeId,
  }) async {
    if (shouldFail) {
      throw const ApiException(
        type: ApiErrorType.serverError,
        message: 'Tailoring failed',
        statusCode: 500,
      );
    }
    return mockTailoring;
  }
}

void main() {
  group('JobController Tests', () {
    late FakeJobService fakeJobService;
    late JobController controller;

    setUp(() {
      fakeJobService = FakeJobService();
      controller = JobController(
        jobService: fakeJobService,
        initialJobs: [],
        initialStatus: JobStateStatus.initial,
      );
    });

    test('Initial state is idle/initial', () {
      expect(controller.status, JobStateStatus.initial);
      expect(controller.jobs, isEmpty);
      expect(controller.selectedJob, isNull);
      expect(controller.currentMatch, isNull);
      expect(controller.currentAnalysis, isNull);
    });

    test('loadJobs populates jobs on success', () async {
      await controller.loadJobs();

      expect(controller.status, JobStateStatus.loaded);
      expect(controller.jobs.length, 1);
      expect(controller.jobs.first.id, 'job-1');
      expect(controller.hasError, isFalse);
    });

    test('loadJobs sets error state on failure', () async {
      fakeJobService.shouldFail = true;

      await controller.loadJobs();

      expect(controller.status, JobStateStatus.error);
      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, 'Server error. Please try again later.');
    });

    test('loadJobDetail fetches and sets selectedJob', () async {
      final job = await controller.loadJobDetail('job-1');

      expect(controller.detailStatus, JobDetailStatus.loaded);
      expect(job, isNotNull);
      expect(job?.id, 'job-1');
      expect(controller.selectedJob?.title, 'Flutter Engineer');
    });

    test('loads persisted views once and does not re-record them', () async {
      fakeJobService.persistedViews = [
        JobView(
          id: 'view-job-1',
          userId: 'u1',
          jobId: 'job-1',
          createdAt: DateTime.now(),
        ),
      ];

      await controller.loadViewedJobs();
      await controller.loadViewedJobs();
      await controller.recordJobView('job-1');

      expect(controller.isJobViewed('job-1'), isTrue);
      expect(fakeJobService.listViewedJobsCallCount, 1);
      expect(fakeJobService.recordJobViewCallCount, 0);
    });

    test('failed view recording remains retryable', () async {
      fakeJobService.shouldFailViewRequest = true;
      await controller.recordJobView('job-1');
      expect(controller.isJobViewed('job-1'), isFalse);

      fakeJobService.shouldFailViewRequest = false;
      await controller.recordJobView('job-1');
      expect(controller.isJobViewed('job-1'), isTrue);
      expect(fakeJobService.recordJobViewCallCount, 2);
    });

    test('signed-out users do not create view records', () async {
      await fakeJobService.apiClient.tokenStorage.clearToken();
      await controller.recordJobView('job-1');
      expect(fakeJobService.recordJobViewCallCount, 0);
      expect(controller.isJobViewed('job-1'), isFalse);
    });

    test('view tracking failure does not block details or match calculation', () async {
      fakeJobService.shouldFailViewRequest = true;
      final job = await controller.loadJobDetail('job-1');
      await Future<void>.delayed(Duration.zero);

      final match = await controller.calculateMatch(jobId: 'job-1', resumeId: 'r1');
      expect(job?.id, 'job-1');
      expect(controller.detailStatus, JobDetailStatus.loaded);
      expect(match, isNotNull);
      expect(controller.isJobViewed('job-1'), isFalse);
    });

    test('calculateMatch sets currentMatch', () async {
      final match = await controller.calculateMatch(
        jobId: 'job-1',
        resumeId: 'r1',
      );

      expect(controller.matchStatus, MatchStateStatus.loaded);
      expect(match, isNotNull);
      expect(controller.currentMatch?.score, 90);
      expect(controller.matchesByJobId['job-1'], isNotNull);
    });

    test('analyzeJob sets currentAnalysis', () async {
      final analysis = await controller.analyzeJob(
        jobId: 'job-1',
        resumeId: 'r1',
      );

      expect(controller.analysisStatus, AnalysisStateStatus.loaded);
      expect(analysis, isNotNull);
      expect(controller.currentAnalysis?.summary, 'Great fit');
    });

    test('tailorResume stores a response from the backend contract', () async {
      final tailoring = await controller.tailorResume(
        jobId: 'job-1',
        resumeId: 'r1',
      );

      expect(controller.tailoringStatus, TailoringStateStatus.loaded);
      expect(tailoring?.tailoredResume, 'Tailored Flutter resume');
      expect(controller.currentTailoring?.changesMade, ['Refined summary']);
    });

    test('signed-in loadJobs passes useSavedPreferences=true', () async {
      await controller.loadJobs();
      expect(fakeJobService.lastUseSavedPreferences, isTrue);
    });

    test('signed-out loadJobs passes useSavedPreferences=null', () async {
      await fakeJobService.apiClient.tokenStorage.clearToken();
      await controller.loadJobs();
      expect(fakeJobService.lastUseSavedPreferences, isNull);
    });

    test('loadUserMatches filters matches by primaryResumeId', () async {
      await controller.loadUserMatches(primaryResumeId: 'r1');
      expect(controller.matchesByJobId.length, 1);
      expect(controller.matchesByJobId['job-1']?.resumeId, 'r1');
      expect(controller.matchesByJobId.containsKey('job-2'), isFalse);
    });

    test(
      'calculateMatch avoids repeated backend calls for same job/resume pair',
      () async {
        await controller.calculateMatch(jobId: 'job-1', resumeId: 'r1');
        expect(fakeJobService.createMatchCallCount, 1);

        await controller.calculateMatch(jobId: 'job-1', resumeId: 'r1');
        expect(fakeJobService.createMatchCallCount, 1);
      },
    );

    test('calculateMatch fails when resumeId is empty', () async {
      final result = await controller.calculateMatch(
        jobId: 'job-1',
        resumeId: '',
      );
      expect(result, isNull);
      expect(
        controller.matchErrorMessage,
        contains('primary resume is required'),
      );
    });
  });
}
