import '../../../core/network/api_client.dart';
import '../domain/job_source.dart';

class JobSourceService {
  final ApiClient apiClient;

  JobSourceService({required this.apiClient});

  Future<List<JobSourceItem>> fetchAvailableSources() async {
    final response = await apiClient.get('/job-sources');
    final list = response as List<dynamic>;
    return list
        .map((json) => JobSourceItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> fetchSelectedSourceIds() async {
    final response = await apiClient.get('/job-sources/selected');
    final data = response as Map<String, dynamic>;
    final list = data['selected_source_ids'] as List<dynamic>? ?? [];
    return list.cast<String>();
  }

  Future<List<String>> updateSelectedSourceIds(List<String> sourceIds) async {
    final response = await apiClient.put(
      '/job-sources/selected',
      body: {'source_ids': sourceIds},
    );
    final data = response as Map<String, dynamic>;
    final list = data['selected_source_ids'] as List<dynamic>? ?? [];
    return list.cast<String>();
  }
}
