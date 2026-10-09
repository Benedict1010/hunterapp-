import '../../../core/network/api_client.dart';
import '../domain/resume.dart';
import '../domain/resume_version.dart';

class ResumeService {
  final ApiClient apiClient;

  ResumeService({required this.apiClient});

  Future<List<Resume>> listResumes() async {
    final response = await apiClient.get('/resumes');
    final list = response as List<dynamic>;
    return list
        .map((json) => Resume.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Resume> getResume(String id) async {
    final response = await apiClient.get('/resumes/$id');
    return Resume.fromJson(response as Map<String, dynamic>);
  }

  Future<Resume> uploadResume({
    required String filePath,
    String? fileName,
    List<int>? bytes,
  }) async {
    final response = await apiClient.postMultipart(
      '/resumes',
      fileField: 'file',
      filePath: filePath,
      fileName: fileName,
      bytes: bytes,
    );
    return Resume.fromJson(response as Map<String, dynamic>);
  }

  Future<Resume> updateResume(
    String id, {
    required String filePath,
    String? fileName,
    List<int>? bytes,
  }) async {
    final response = await apiClient.putMultipart(
      '/resumes/$id',
      fileField: 'file',
      filePath: filePath,
      fileName: fileName,
      bytes: bytes,
    );
    return Resume.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteResume(String id) async {
    await apiClient.delete('/resumes/$id');
  }

  Future<Resume> setPrimary(String id) async {
    final response = await apiClient.patch('/resumes/$id/primary');
    return Resume.fromJson(response as Map<String, dynamic>);
  }

  Future<Resume> extractResume(String id) async {
    final response = await apiClient.post('/resumes/$id/extract');
    return Resume.fromJson(response as Map<String, dynamic>);
  }

  Future<List<ResumeVersion>> listVersions(String id) async {
    final response = await apiClient.get('/resumes/$id/versions');
    final list = response as List<dynamic>;
    return list
        .map((json) => ResumeVersion.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ResumeVersion> getVersion(String id, String versionId) async {
    final response = await apiClient.get('/resumes/$id/versions/$versionId');
    return ResumeVersion.fromJson(response as Map<String, dynamic>);
  }

  Future<List<int>> downloadResume(String id) async {
    return await apiClient.getBytes('/resumes/$id/download');
  }
}
