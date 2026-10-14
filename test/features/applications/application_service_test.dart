import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/applications/data/application_service.dart';
import 'package:hunter/features/applications/domain/job_application.dart';

import '../../core/api_client_test.dart';

void main() {
  group('ApplicationService Tests', () {
    late InMemoryTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage('test-token');
    });

    test(
      'listApplications sends GET /applications with optional status',
      () async {
        final mockClient = MockHttpClient((request) async {
          expect(request.url.path, equals('/applications'));
          expect(request.url.queryParameters['status'], equals('applied'));

          return http.Response(
            jsonEncode([
              {
                'id': 'app-1',
                'user_id': 'u-1',
                'job_id': 'j-1',
                'resume_version_id': 'ver-1',
                'status': 'applied',
                'created_at': '2026-03-20T10:00:00Z',
                'updated_at': '2026-03-20T10:00:00Z',
              },
            ]),
            200,
          );
        });

        final apiClient = ApiClient(
          apiConfig: const ApiConfig(),
          tokenStorage: tokenStorage,
          client: mockClient,
        );
        final service = ApplicationService(apiClient: apiClient);

        final result = await service.listApplications(
          status: ApplicationStatus.applied,
        );

        expect(result.length, 1);
        expect(result.first.id, 'app-1');
        expect(result.first.status, ApplicationStatus.applied);
      },
    );

    test('getApplication sends GET /applications/{id}', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, equals('/applications/app-123'));

        return http.Response(
          jsonEncode({
            'id': 'app-123',
            'user_id': 'u-1',
            'job_id': 'j-1',
            'resume_version_id': 'ver-1',
            'status': 'interview',
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
      final service = ApplicationService(apiClient: apiClient);

      final app = await service.getApplication('app-123');

      expect(app.id, 'app-123');
      expect(app.status, ApplicationStatus.interview);
    });

    test('createApplication sends POST /applications', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/applications'));
        final body =
            jsonDecode((request as http.Request).body) as Map<String, dynamic>;
        expect(body['job_id'], equals('j-100'));
        expect(body['resume_version_id'], equals('ver-200'));

        return http.Response(
          jsonEncode({
            'id': 'app-new',
            'user_id': 'u-1',
            'job_id': 'j-100',
            'resume_version_id': 'ver-200',
            'status': 'applied',
            'created_at': '2026-03-20T10:00:00Z',
            'updated_at': '2026-03-20T10:00:00Z',
          }),
          201,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = ApplicationService(apiClient: apiClient);

      final newApp = await service.createApplication(
        jobId: 'j-100',
        resumeVersionId: 'ver-200',
      );

      expect(newApp.id, 'app-new');
      expect(newApp.jobId, 'j-100');
    });

    test('updateApplicationStatus sends PATCH /applications/{id}', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('PATCH'));
        expect(request.url.path, equals('/applications/app-123'));
        final body =
            jsonDecode((request as http.Request).body) as Map<String, dynamic>;
        expect(body['status'], equals('interview'));

        return http.Response(
          jsonEncode({
            'id': 'app-123',
            'user_id': 'u-1',
            'job_id': 'j-1',
            'resume_version_id': 'ver-1',
            'status': 'interview',
            'created_at': '2026-03-20T10:00:00Z',
            'updated_at': '2026-03-20T12:00:00Z',
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = ApplicationService(apiClient: apiClient);

      final updated = await service.updateApplicationStatus(
        'app-123',
        ApplicationStatus.interview,
      );

      expect(updated.status, ApplicationStatus.interview);
    });

    test('listTimeline sends GET /applications/{id}/timeline', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, equals('/applications/app-123/timeline'));

        return http.Response(
          jsonEncode([
            {
              'id': 'tm-1',
              'application_id': 'app-123',
              'status': 'applied',
              'note': 'Created',
              'created_at': '2026-03-20T10:00:00Z',
              'updated_at': '2026-03-20T10:00:00Z',
            },
          ]),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = ApplicationService(apiClient: apiClient);

      final events = await service.listTimeline('app-123');

      expect(events.length, 1);
      expect(events.first.id, 'tm-1');
    });

    test(
      'getExternalLink sends GET /applications/{id}/external-link',
      () async {
        final mockClient = MockHttpClient((request) async {
          expect(
            request.url.path,
            equals('/applications/app-123/external-link'),
          );

          return http.Response(
            jsonEncode({
              'application_id': 'app-123',
              'application_url': 'https://careers.example.com/apply/123',
              'source': 'linkedin',
            }),
            200,
          );
        });

        final apiClient = ApiClient(
          apiConfig: const ApiConfig(),
          tokenStorage: tokenStorage,
          client: mockClient,
        );
        final service = ApplicationService(apiClient: apiClient);

        final link = await service.getExternalLink('app-123');

        expect(link.applicationId, 'app-123');
        expect(link.applicationUrl, 'https://careers.example.com/apply/123');
      },
    );
  });
}
