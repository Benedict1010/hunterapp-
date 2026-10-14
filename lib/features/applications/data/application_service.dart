import '../../../core/network/api_client.dart';
import '../domain/job_application.dart';

class ApplicationService {
  final ApiClient apiClient;

  ApplicationService({required this.apiClient});

  Future<List<Application>> listApplications({
    ApplicationStatus? status,
  }) async {
    final queryParams = <String, String>{
      if (status != null) 'status': status.value,
    };
    final uri = Uri(path: '/applications', queryParameters: queryParams);
    final response = await apiClient.get(uri.toString());
    final list = response as List<dynamic>;
    return list
        .map((json) => Application.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Application> getApplication(String applicationId) async {
    final response = await apiClient.get('/applications/$applicationId');
    return Application.fromJson(response as Map<String, dynamic>);
  }

  Future<ApplicationExternalLink> getExternalLink(String applicationId) async {
    final response = await apiClient.get(
      '/applications/$applicationId/external-link',
    );
    return ApplicationExternalLink.fromJson(response as Map<String, dynamic>);
  }

  Future<Application> createApplication({
    required String jobId,
    required String resumeVersionId,
    String? applicationUrl,
    String? source,
    ApplicationStatus status = ApplicationStatus.applied,
    DateTime? appliedAt,
  }) async {
    final body = <String, dynamic>{
      'job_id': jobId,
      'resume_version_id': resumeVersionId,
      'status': status.value,
      if (applicationUrl != null && applicationUrl.isNotEmpty)
        'application_url': applicationUrl,
      if (source != null && source.isNotEmpty) 'source': source,
      if (appliedAt != null) 'applied_at': appliedAt.toIso8601String(),
    };

    final response = await apiClient.post('/applications', body: body);
    return Application.fromJson(response as Map<String, dynamic>);
  }

  Future<Application> updateApplicationStatus(
    String applicationId,
    ApplicationStatus status, {
    String? applicationUrl,
    String? source,
    DateTime? appliedAt,
  }) async {
    final body = <String, dynamic>{
      'status': status.value,
      if (applicationUrl != null && applicationUrl.isNotEmpty)
        'application_url': applicationUrl,
      if (source != null && source.isNotEmpty) 'source': source,
      if (appliedAt != null) 'applied_at': appliedAt.toIso8601String(),
    };

    final response = await apiClient.patch(
      '/applications/$applicationId',
      body: body,
    );
    return Application.fromJson(response as Map<String, dynamic>);
  }

  Future<List<ApplicationTimelineEvent>> listTimeline(
    String applicationId,
  ) async {
    final response = await apiClient.get(
      '/applications/$applicationId/timeline',
    );
    final list = response as List<dynamic>;
    return list
        .map(
          (json) =>
              ApplicationTimelineEvent.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ApplicationTimelineEvent> getTimelineEvent(
    String applicationId,
    String timelineId,
  ) async {
    final response = await apiClient.get(
      '/applications/$applicationId/timeline/$timelineId',
    );
    return ApplicationTimelineEvent.fromJson(response as Map<String, dynamic>);
  }

  Future<ApplicationTimelineEvent> addTimelineEvent(
    String applicationId,
    ApplicationStatus status, {
    String? note,
  }) async {
    final body = <String, dynamic>{
      'status': status.value,
      if (note != null && note.isNotEmpty) 'note': note,
    };

    final response = await apiClient.post(
      '/applications/$applicationId/timeline',
      body: body,
    );
    return ApplicationTimelineEvent.fromJson(response as Map<String, dynamic>);
  }
}
