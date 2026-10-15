import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/preferences/data/job_preference_service.dart';
import 'package:hunter/features/preferences/domain/job_preference.dart';
import 'package:hunter/features/preferences/presentation/job_preference_controller.dart';

import '../../core/api_client_test.dart';

void main() {
  group('JobPreferenceController Tests', () {
    late InMemoryTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage('valid-token');
    });

    test('loadPreferences fetches saved preference from backend', () async {
      final mockClient = MockHttpClient((request) async {
        if (request.url.path == '/preferences') {
          return http.Response(
            jsonEncode({
              'id': 'p-1',
              'preferred_roles': ['Data Scientist'],
              'job_type': 'Internship',
              'work_mode': 'On-site',
              'min_salary': 15000,
              'preferred_locations': ['Delhi, DL'],
              'min_match_threshold': 75,
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
      final service = JobPreferenceService(apiClient: apiClient);
      final controller = JobPreferenceController(preferenceService: service);

      expect(controller.status, JobPreferenceStateStatus.initial);
      await controller.loadPreferences();

      expect(controller.status, JobPreferenceStateStatus.loaded);
      expect(controller.preference.preferredRoles, ['Data Scientist']);
      expect(controller.preference.minSalary, 15000);
    });

    test('savePreferences sends update to backend', () async {
      final mockClient = MockHttpClient((request) async {
        if (request.method == 'PUT' && request.url.path == '/preferences') {
          return http.Response(
            jsonEncode({
              'id': 'p-1',
              'preferred_roles': ['Frontend Engineer'],
              'job_type': 'Full-time',
              'work_mode': 'Remote',
              'min_salary': 30000,
              'preferred_locations': ['Remote'],
              'min_match_threshold': 85,
            }),
            200,
          );
        }
        return http.Response('Error', 400);
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = JobPreferenceService(apiClient: apiClient);
      final controller = JobPreferenceController(preferenceService: service);

      controller.updateLocalPreference(const JobPreference(minSalary: 30000));
      final success = await controller.savePreferences();

      expect(success, isTrue);
      expect(controller.status, JobPreferenceStateStatus.loaded);
      expect(controller.preference.minSalary, 30000);
    });

    test('savePreferences unauthenticated returns error', () async {
      tokenStorage = InMemoryTokenStorage(null);
      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: MockHttpClient((_) async => http.Response('{}', 200)),
      );
      final controller = JobPreferenceController(
        preferenceService: JobPreferenceService(apiClient: apiClient),
      );

      final success = await controller.savePreferences();
      expect(success, isFalse);
      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, contains('sign in'));
    });
  });
}
