import '../../../core/network/api_client.dart';
import '../domain/job_preference.dart';

class JobPreferenceService {
  final ApiClient apiClient;

  JobPreferenceService({required this.apiClient});

  Future<JobPreference?> getPreferences() async {
    final response = await apiClient.get('/preferences');
    if (response == null) return null;
    return JobPreference.fromJson(response as Map<String, dynamic>);
  }

  Future<JobPreference> updatePreferences(JobPreference preference) async {
    final response = await apiClient.put(
      '/preferences',
      body: preference.toJson(),
    );
    return JobPreference.fromJson(response as Map<String, dynamic>);
  }
}
