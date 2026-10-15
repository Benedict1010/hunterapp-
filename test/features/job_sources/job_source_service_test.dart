import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/job_sources/data/job_source_service.dart';

import '../../core/api_client_test.dart';

void main() {
  group('JobSourceService Tests', () {
    late InMemoryTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage('test-token');
    });

    test('fetchAvailableSources calls GET /job-sources', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, equals('/job-sources'));

        return http.Response(
          jsonEncode([
            {
              'id': 'src-1',
              'name': 'LinkedIn',
              'base_url': 'https://linkedin.com',
              'description': 'Professional network',
              'is_available': false,
            },
            {
              'id': 'src-2',
              'name': 'Mock Job Source',
              'base_url': 'https://mock.com',
              'description': 'Mock feed',
              'is_available': true,
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
      final service = JobSourceService(apiClient: apiClient);

      final sources = await service.fetchAvailableSources();
      expect(sources.length, 2);
      expect(sources.first.name, 'LinkedIn');
      expect(sources.last.isAvailable, true);
    });

    test('fetchSelectedSourceIds calls GET /job-sources/selected', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, equals('/job-sources/selected'));

        return http.Response(
          jsonEncode({
            'selected_source_ids': ['src-1', 'src-2'],
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = JobSourceService(apiClient: apiClient);

      final selected = await service.fetchSelectedSourceIds();
      expect(selected, equals(['src-1', 'src-2']));
    });

    test('updateSelectedSourceIds calls PUT /job-sources/selected', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('PUT'));
        expect(request.url.path, equals('/job-sources/selected'));
        final req = request as http.Request;
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['source_ids'], equals(['src-1']));

        return http.Response(
          jsonEncode({
            'selected_source_ids': ['src-1'],
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = JobSourceService(apiClient: apiClient);

      final updated = await service.updateSelectedSourceIds(['src-1']);
      expect(updated, equals(['src-1']));
    });
  });
}
