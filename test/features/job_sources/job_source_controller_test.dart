import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/job_sources/data/job_source_service.dart';
import 'package:hunter/features/job_sources/presentation/job_source_controller.dart';

import '../../core/api_client_test.dart';

void main() {
  group('JobSourceController Tests', () {
    late InMemoryTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage('valid-token');
    });

    test('loadSources fetches available and selected sources', () async {
      final mockClient = MockHttpClient((request) async {
        if (request.url.path == '/job-sources') {
          return http.Response(
            jsonEncode([
              {'id': 'src-1', 'name': 'LinkedIn', 'is_available': false},
              {'id': 'src-2', 'name': 'Unstop', 'is_available': true},
            ]),
            200,
          );
        } else if (request.url.path == '/job-sources/selected') {
          return http.Response(
            jsonEncode({
              'selected_source_ids': ['src-1'],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = JobSourceService(apiClient: apiClient);
      final controller = JobSourceController(jobSourceService: service);

      expect(controller.status, JobSourceStateStatus.initial);
      await controller.loadSources();

      expect(controller.status, JobSourceStateStatus.loaded);
      expect(controller.sources.length, 2);
      expect(controller.isSelected('src-1'), isTrue);
      expect(controller.isSelected('src-2'), isFalse);
    });

    test('toggleSource updates local selected state', () {
      final controller = JobSourceController(
        jobSourceService: JobSourceService(
          apiClient: ApiClient(
            apiConfig: const ApiConfig(),
            tokenStorage: tokenStorage,
            client: MockHttpClient((_) async => http.Response('{}', 200)),
          ),
        ),
        initialSelectedIds: {'src-1'},
      );

      expect(controller.isSelected('src-1'), isTrue);
      controller.toggleSource('src-1');
      expect(controller.isSelected('src-1'), isFalse);
      controller.toggleSource('src-1');
      expect(controller.isSelected('src-1'), isTrue);
    });

    test('loadSources does not imply saved selections when signed out', () async {
      tokenStorage = InMemoryTokenStorage(null);
      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: MockHttpClient(
          (_) async => http.Response(
            jsonEncode([
              {'id': 'src-1', 'name': 'LinkedIn', 'is_available': false},
            ]),
            200,
          ),
        ),
      );
      final controller = JobSourceController(
        jobSourceService: JobSourceService(apiClient: apiClient),
      );

      await controller.loadSources();

      expect(controller.status, JobSourceStateStatus.loaded);
      expect(controller.selectedIds, isEmpty);
    });

    test('saveSelections persists selection to backend', () async {
      final mockClient = MockHttpClient((request) async {
        if (request.method == 'PUT' &&
            request.url.path == '/job-sources/selected') {
          return http.Response(
            jsonEncode({
              'selected_source_ids': ['src-1', 'src-2'],
            }),
            200,
          );
        }
        return http.Response('Bad Request', 400);
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = JobSourceService(apiClient: apiClient);
      final controller = JobSourceController(
        jobSourceService: service,
        initialSelectedIds: {'src-1', 'src-2'},
      );

      final success = await controller.saveSelections();
      expect(success, isTrue);
      expect(controller.status, JobSourceStateStatus.loaded);
      expect(controller.selectedIds, equals({'src-1', 'src-2'}));
    });

    test('saveSelections unauthenticated returns error', () async {
      tokenStorage = InMemoryTokenStorage(null);
      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: MockHttpClient((_) async => http.Response('{}', 200)),
      );
      final controller = JobSourceController(
        jobSourceService: JobSourceService(apiClient: apiClient),
      );

      final success = await controller.saveSelections();
      expect(success, isFalse);
      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, contains('sign in'));
    });
  });
}
