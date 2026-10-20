import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/jobs/data/job_service.dart';

import '../../core/api_client_test.dart';

void main() {
  group('JobService Tests', () {
    late InMemoryTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage('test-token');
    });

    test('listJobs sends GET /jobs with query parameters', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, equals('/jobs'));
        expect(request.url.queryParameters['limit'], equals('20'));
        expect(request.url.queryParameters['offset'], equals('0'));
        expect(request.url.queryParameters['company'], equals('TechCorp'));

        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 'job-1',
                'title': 'Flutter Lead',
                'company': 'TechCorp',
                'external_url': 'https://techcorp.com/job/1',
                'source': 'LinkedIn',
                'skills': [
                  {'name': 'Flutter', 'importance': 1.0},
                ],
              },
            ],
            'total': 1,
            'limit': 20,
            'offset': 0,
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = JobService(apiClient: apiClient);

      final response = await service.listJobs(company: 'TechCorp');

      expect(response.total, equals(1));
      expect(response.items.first.id, equals('job-1'));
      expect(response.items.first.company, equals('TechCorp'));
    });

    test(
      'listJobs serializes use_saved_preferences=true when requested',
      () async {
        final mockClient = MockHttpClient((request) async {
          expect(request.url.path, equals('/jobs'));
          expect(
            request.url.queryParameters['use_saved_preferences'],
            equals('true'),
          );

          return http.Response(
            jsonEncode({'items': [], 'total': 0, 'limit': 20, 'offset': 0}),
            200,
          );
        });

        final apiClient = ApiClient(
          apiConfig: const ApiConfig(),
          tokenStorage: tokenStorage,
          client: mockClient,
        );
        final service = JobService(apiClient: apiClient);

        final response = await service.listJobs(useSavedPreferences: true);
        expect(response.total, equals(0));
      },
    );

    test('public listJobs does not include use_saved_preferences', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, equals('/jobs'));
        expect(
          request.url.queryParameters.containsKey('use_saved_preferences'),
          isFalse,
        );

        return http.Response(
          jsonEncode({'items': [], 'total': 0, 'limit': 20, 'offset': 0}),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = JobService(apiClient: apiClient);

      final response = await service.listJobs(useSavedPreferences: false);
      expect(response.total, equals(0));
    });

    test('getJob sends GET /jobs/{job_id}', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, equals('/jobs/job-123'));

        return http.Response(
          jsonEncode({
            'id': 'job-123',
            'title': 'Dart Developer',
            'company': 'Awesome Inc',
            'external_url': 'https://awesome.com/jobs/123',
            'source': 'Unstop',
            'skills': [],
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = JobService(apiClient: apiClient);

      final job = await service.getJob('job-123');

      expect(job.id, equals('job-123'));
      expect(job.title, equals('Dart Developer'));
    });

    test('job view requests use the dedicated endpoints', () async {
      var requestCount = 0;
      final mockClient = MockHttpClient((request) async {
        requestCount++;
        if (request.method == 'GET') {
          expect(request.url.path, '/jobs/viewed');
          return http.Response(jsonEncode([]), 200);
        }
        expect(request.method, 'POST');
        expect(request.url.path, '/jobs/job-123/view');
        return http.Response(
          jsonEncode({
            'id': 'view-1',
            'user_id': 'user-1',
            'job_id': 'job-123',
            'created_at': '2026-10-20T10:00:00Z',
          }),
          200,
        );
      });
      final service = JobService(
        apiClient: ApiClient(
          apiConfig: const ApiConfig(),
          tokenStorage: tokenStorage,
          client: mockClient,
        ),
      );

      expect(await service.listViewedJobs(), isEmpty);
      expect((await service.recordJobView('job-123')).jobId, 'job-123');
      expect(requestCount, 2);
    });

    test('createOrGetMatch sends POST /matches/jobs/{job_id}', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/matches/jobs/job-123'));
        final body =
            jsonDecode((request as http.Request).body) as Map<String, dynamic>;
        expect(body['resume_id'], equals('res-456'));

        return http.Response(
          jsonEncode({
            'id': 'match-1',
            'user_id': 'user-1',
            'resume_id': 'res-456',
            'job_id': 'job-123',
            'match_score': 92.0,
            'matched_skills': ['Dart', 'Flutter'],
            'missing_skills': [],
            'explanation': 'Great fit!',
            'created_at': '2026-03-20T10:00:00Z',
            'updated_at': '2026-03-20T10:00:00Z',
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = JobService(apiClient: apiClient);

      final match = await service.createOrGetMatch(
        jobId: 'job-123',
        resumeId: 'res-456',
      );

      expect(match.id, equals('match-1'));
      expect(match.score, equals(92));
      expect(match.matchedSkills, contains('Flutter'));
    });

    test('analyzeJobMatch sends POST /matches/jobs/{job_id}/analyze', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/matches/jobs/job-123/analyze'));
        final body =
            jsonDecode((request as http.Request).body) as Map<String, dynamic>;
        expect(body['resume_id'], equals('res-456'));

        return http.Response(
          jsonEncode({
            'summary': 'Excellent candidate match.',
            'strengths': ['Strong Dart knowledge'],
            'missing_skills': ['PostgreSQL'],
            'recommendations': ['Learn SQL basics'],
            'raw_score': 88.0,
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = JobService(apiClient: apiClient);

      final analysis = await service.analyzeJobMatch(
        jobId: 'job-123',
        resumeId: 'res-456',
      );

      expect(analysis.summary, equals('Excellent candidate match.'));
      expect(analysis.strengths, contains('Strong Dart knowledge'));
      expect(analysis.rawScore, equals(88.0));
    });

    test('tailorResume sends POST /matches/jobs/{job_id}/tailor', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/matches/jobs/job-123/tailor'));
        final body =
            jsonDecode((request as http.Request).body) as Map<String, dynamic>;
        expect(body['resume_id'], equals('res-456'));

        return http.Response(
          jsonEncode({
            'tailored_resume': 'Tailored resume text.',
            'changes_made': ['Refined summary'],
            'warnings': ['Verify all claims'],
          }),
          200,
        );
      });
      final service = JobService(
        apiClient: ApiClient(
          apiConfig: const ApiConfig(),
          tokenStorage: tokenStorage,
          client: mockClient,
        ),
      );

      final tailoring = await service.tailorResume(
        jobId: 'job-123',
        resumeId: 'res-456',
      );

      expect(tailoring.tailoredResume, 'Tailored resume text.');
      expect(tailoring.changesMade, ['Refined summary']);
    });
  });
}
