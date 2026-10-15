import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/preferences/data/job_preference_service.dart';
import 'package:hunter/features/preferences/domain/job_preference.dart';

import '../../core/api_client_test.dart';

void main() {
  group('JobPreferenceService Tests', () {
    late InMemoryTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage('test-token');
    });

    test('getPreferences calls GET /preferences', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, equals('/preferences'));

        return http.Response(
          jsonEncode({
            'id': 'pref-1',
            'user_id': 'u-1',
            'preferred_roles': ['Frontend Engineer'],
            'job_type': 'Full-time',
            'work_mode': 'Remote',
            'min_salary': 30000,
            'preferred_locations': ['Remote'],
            'min_match_threshold': 85,
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = JobPreferenceService(apiClient: apiClient);

      final pref = await service.getPreferences();
      expect(pref, isNotNull);
      expect(pref!.preferredRoles, ['Frontend Engineer']);
      expect(pref.minSalary, 30000);
    });

    test('updatePreferences calls PUT /preferences', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('PUT'));
        expect(request.url.path, equals('/preferences'));
        final req = request as http.Request;
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['min_salary'], equals(40000));

        return http.Response(
          jsonEncode({
            'id': 'pref-1',
            'user_id': 'u-1',
            'preferred_roles': ['Backend Dev'],
            'job_type': 'Contract',
            'work_mode': 'Hybrid',
            'min_salary': 40000,
            'preferred_locations': ['Mumbai, MH'],
            'min_match_threshold': 90,
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = JobPreferenceService(apiClient: apiClient);

      final updated = await service.updatePreferences(
        const JobPreference(minSalary: 40000),
      );
      expect(updated.minSalary, 40000);
      expect(updated.workMode, 'Hybrid');
    });
  });
}
