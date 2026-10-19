import '../../../core/network/api_client.dart';
import '../domain/ai_analysis.dart';
import '../domain/ai_tailoring.dart';
import '../domain/job.dart';
import '../domain/job_match.dart';

class JobService {
  final ApiClient apiClient;

  JobService({required this.apiClient});

  Future<JobListResponse> listJobs({
    String? company,
    String? location,
    String? jobType,
    bool? useSavedPreferences,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (company != null && company.isNotEmpty) 'company': company,
      if (location != null && location.isNotEmpty) 'location': location,
      if (jobType != null && jobType.isNotEmpty) 'job_type': jobType,
      if (useSavedPreferences == true) 'use_saved_preferences': 'true',
    };

    final Uri uri = Uri(path: '/jobs', queryParameters: queryParams);
    final response = await apiClient.get(uri.toString());
    return JobListResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<Job> getJob(String jobId) async {
    final response = await apiClient.get('/jobs/$jobId');
    return Job.fromJson(response as Map<String, dynamic>);
  }

  Future<JobMatch> createOrGetMatch({
    required String jobId,
    required String resumeId,
  }) async {
    final response = await apiClient.post(
      '/matches/jobs/$jobId',
      body: {'resume_id': resumeId},
    );
    return JobMatch.fromJson(response as Map<String, dynamic>);
  }

  Future<List<JobMatch>> listMatches() async {
    final response = await apiClient.get('/matches');
    final list = response as List<dynamic>;
    return list
        .map((json) => JobMatch.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<JobMatch> getMatch(String matchId) async {
    final response = await apiClient.get('/matches/$matchId');
    return JobMatch.fromJson(response as Map<String, dynamic>);
  }

  Future<AiAnalysis> analyzeJobMatch({
    required String jobId,
    required String resumeId,
  }) async {
    final response = await apiClient.post(
      '/matches/jobs/$jobId/analyze',
      body: {'resume_id': resumeId},
    );
    return AiAnalysis.fromJson(response as Map<String, dynamic>);
  }

  Future<AiTailoring> tailorResume({
    required String jobId,
    required String resumeId,
  }) async {
    final response = await apiClient.post(
      '/matches/jobs/$jobId/tailor',
      body: {'resume_id': resumeId},
    );
    return AiTailoring.fromJson(response as Map<String, dynamic>);
  }
}
