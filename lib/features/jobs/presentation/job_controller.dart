import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/job_service.dart';
import '../data/mock_jobs.dart';
import '../domain/ai_analysis.dart';
import '../domain/ai_tailoring.dart';
import '../domain/job.dart';
import '../domain/job_match.dart';

enum JobStateStatus { initial, loading, loaded, error }

enum JobDetailStatus { initial, loading, loaded, error }

enum MatchStateStatus { initial, loading, loaded, error }

enum AnalysisStateStatus { initial, loading, loaded, error }

enum TailoringStateStatus { initial, loading, loaded, error }

class JobController extends ChangeNotifier {
  final JobService jobService;

  JobStateStatus _status;
  JobDetailStatus _detailStatus = JobDetailStatus.loaded;
  MatchStateStatus _matchStatus = MatchStateStatus.initial;
  AnalysisStateStatus _analysisStatus = AnalysisStateStatus.initial;
  TailoringStateStatus _tailoringStatus = TailoringStateStatus.initial;

  List<Job> _jobs;
  int _totalJobs;
  Job? _selectedJob;
  JobMatch? _currentMatch;
  AiAnalysis? _currentAnalysis;
  AiTailoring? _currentTailoring;
  final Map<String, JobMatch> _matchesByJobId = {};

  String? _errorMessage;
  String? _matchErrorMessage;
  String? _analysisErrorMessage;
  String? _tailoringErrorMessage;

  JobController({
    required this.jobService,
    List<Job>? initialJobs,
    JobStateStatus initialStatus = JobStateStatus.loaded,
    AiTailoring? initialTailoring,
  }) : _jobs = initialJobs ?? List.of(defaultMockJobs),
       _totalJobs = (initialJobs ?? defaultMockJobs).length,
       _selectedJob = (initialJobs ?? defaultMockJobs).isNotEmpty
           ? (initialJobs ?? defaultMockJobs).first
           : null,
       _currentTailoring = initialTailoring,
       _status = initialStatus;

  JobStateStatus get status => _status;
  JobDetailStatus get detailStatus => _detailStatus;
  MatchStateStatus get matchStatus => _matchStatus;
  AnalysisStateStatus get analysisStatus => _analysisStatus;
  TailoringStateStatus get tailoringStatus => _tailoringStatus;

  List<Job> get jobs => List.unmodifiable(_jobs);
  int get totalJobs => _totalJobs;
  Job? get selectedJob => _selectedJob;
  JobMatch? get currentMatch => _currentMatch;
  AiAnalysis? get currentAnalysis => _currentAnalysis;
  AiTailoring? get currentTailoring => _currentTailoring;
  Map<String, JobMatch> get matchesByJobId => Map.unmodifiable(_matchesByJobId);

  String? get errorMessage => _errorMessage;
  String? get matchErrorMessage => _matchErrorMessage;
  String? get analysisErrorMessage => _analysisErrorMessage;
  String? get tailoringErrorMessage => _tailoringErrorMessage;

  bool get isLoadingJobs => _status == JobStateStatus.loading;
  bool get isLoadingDetail => _detailStatus == JobDetailStatus.loading;
  bool get isCalculatingMatch => _matchStatus == MatchStateStatus.loading;
  bool get isAnalyzing => _analysisStatus == AnalysisStateStatus.loading;
  bool get isTailoring => _tailoringStatus == TailoringStateStatus.loading;

  bool get hasError => _status == JobStateStatus.error;

  void selectJob(Job? job) {
    _selectedJob = job;
    _currentMatch = job != null ? _matchesByJobId[job.id] : null;
    _currentAnalysis = null;
    _matchStatus = _currentMatch != null
        ? MatchStateStatus.loaded
        : MatchStateStatus.initial;
    _analysisStatus = AnalysisStateStatus.initial;
    _tailoringStatus = TailoringStateStatus.initial;
    _currentTailoring = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _matchErrorMessage = null;
    _analysisErrorMessage = null;
    _tailoringErrorMessage = null;
    if (_status == JobStateStatus.error) {
      _status = JobStateStatus.loaded;
    }
    notifyListeners();
  }

  Future<void> loadJobs({
    String? company,
    String? location,
    String? jobType,
    int limit = 20,
    int offset = 0,
  }) async {
    _status = JobStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await jobService.apiClient.tokenStorage.getToken();
      final isSignedIn = token != null && token.isNotEmpty;

      final response = await jobService.listJobs(
        company: company,
        location: location,
        jobType: jobType,
        useSavedPreferences: isSignedIn ? true : null,
        limit: limit,
        offset: offset,
      );
      _jobs = response.items;
      _totalJobs = response.total;
      _status = JobStateStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = JobStateStatus.error;
    } catch (e) {
      _errorMessage = 'Failed to load jobs.';
      _status = JobStateStatus.error;
    }

    notifyListeners();
  }

  Future<void> loadUserMatches({String? primaryResumeId}) async {
    try {
      final token = await jobService.apiClient.tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        _matchesByJobId.clear();
        notifyListeners();
        return;
      }
      final matches = await jobService.listMatches();
      _matchesByJobId.clear();
      if (primaryResumeId != null) {
        for (final match in matches) {
          if (match.resumeId == primaryResumeId) {
            _matchesByJobId[match.jobId] = match;
          }
        }
      } else {
        for (final match in matches) {
          _matchesByJobId[match.jobId] = match;
        }
      }
      if (_selectedJob != null) {
        _currentMatch = _matchesByJobId[_selectedJob!.id];
      }
      notifyListeners();
    } catch (_) {
      // Non-fatal if matches couldn't be loaded (e.g. unauthenticated)
    }
  }

  Future<Job?> loadJobDetail(String jobId) async {
    _detailStatus = JobDetailStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await jobService.apiClient.tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        final matches = _jobs.where((j) => j.id == jobId);
        _selectedJob = matches.isNotEmpty
            ? matches.first
            : softwareEngineerIntern;
        _detailStatus = JobDetailStatus.loaded;
        notifyListeners();
        return _selectedJob;
      }

      final job = await jobService.getJob(jobId);
      _selectedJob = job;
      _currentMatch = _matchesByJobId[jobId];
      _detailStatus = JobDetailStatus.loaded;
      notifyListeners();
      return job;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _detailStatus = JobDetailStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to load job details.';
      _detailStatus = JobDetailStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<JobMatch?> calculateMatch({
    required String jobId,
    required String resumeId,
  }) async {
    if (resumeId.isEmpty) {
      _matchErrorMessage =
          'A primary resume is required for match calculation.';
      _matchStatus = MatchStateStatus.error;
      notifyListeners();
      return null;
    }

    final existingMatch = _matchesByJobId[jobId];
    if (existingMatch != null && existingMatch.resumeId == resumeId) {
      _currentMatch = existingMatch;
      _matchStatus = MatchStateStatus.loaded;
      notifyListeners();
      return existingMatch;
    }

    _matchStatus = MatchStateStatus.loading;
    _matchErrorMessage = null;
    notifyListeners();

    try {
      final match = await jobService.createOrGetMatch(
        jobId: jobId,
        resumeId: resumeId,
      );
      _currentMatch = match;
      _matchesByJobId[jobId] = match;
      _matchStatus = MatchStateStatus.loaded;
      notifyListeners();
      return match;
    } on ApiException catch (e) {
      _matchErrorMessage = e.userFriendlyMessage;
      _matchStatus = MatchStateStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      _matchErrorMessage = 'Failed to calculate job match.';
      _matchStatus = MatchStateStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<AiAnalysis?> analyzeJob({
    required String jobId,
    required String resumeId,
  }) async {
    _analysisStatus = AnalysisStateStatus.loading;
    _analysisErrorMessage = null;
    notifyListeners();

    try {
      final analysis = await jobService.analyzeJobMatch(
        jobId: jobId,
        resumeId: resumeId,
      );
      _currentAnalysis = analysis;
      _analysisStatus = AnalysisStateStatus.loaded;
      notifyListeners();
      return analysis;
    } on ApiException catch (e) {
      _analysisErrorMessage = e.userFriendlyMessage;
      _analysisStatus = AnalysisStateStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      _analysisErrorMessage = 'Failed to run AI job analysis.';
      _analysisStatus = AnalysisStateStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<AiTailoring?> tailorResume({
    required String jobId,
    required String resumeId,
  }) async {
    _tailoringStatus = TailoringStateStatus.loading;
    _tailoringErrorMessage = null;
    notifyListeners();

    try {
      final tailoring = await jobService.tailorResume(
        jobId: jobId,
        resumeId: resumeId,
      );
      _currentTailoring = tailoring;
      _tailoringStatus = TailoringStateStatus.loaded;
      notifyListeners();
      return tailoring;
    } on ApiException catch (e) {
      _tailoringErrorMessage = e.userFriendlyMessage;
      _tailoringStatus = TailoringStateStatus.error;
      notifyListeners();
      return null;
    } catch (_) {
      _tailoringErrorMessage = 'Failed to tailor resume.';
      _tailoringStatus = TailoringStateStatus.error;
      notifyListeners();
      return null;
    }
  }
}
