import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/network/api_exception.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/jobs/data/job_service.dart';
import 'package:hunter/features/jobs/domain/ai_analysis.dart';
import 'package:hunter/features/jobs/domain/job.dart';
import 'package:hunter/features/jobs/domain/job_match.dart';
import 'package:hunter/features/jobs/presentation/job_controller.dart';

class FakeJobService implements JobService {
  bool shouldFail = false;

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

  @override
  Future<JobListResponse> listJobs({
    String? company,
    String? location,
    String? jobType,
    int limit = 20,
    int offset = 0,
  }) async {
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
  Future<JobMatch> createOrGetMatch({
    required String jobId,
    required String resumeId,
  }) async {
    if (shouldFail) {
      throw const ApiException(
        type: ApiErrorType.badRequest,
        message: 'Matching failed',
        statusCode: 400,
      );
    }
    return mockMatch;
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
    return [mockMatch];
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
  });
}
