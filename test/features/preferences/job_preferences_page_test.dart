import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hunter/app/app.dart';
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/preferences/data/job_preference_service.dart';
import 'package:hunter/features/preferences/domain/job_preference.dart';
import 'package:hunter/features/preferences/presentation/job_preference_controller.dart';
import 'package:hunter/features/preferences/presentation/job_preferences_page.dart';

import '../../core/api_client_test.dart';

void main() {
  testWidgets('JobPreferencesPage renders form controls and title', (
    WidgetTester tester,
  ) async {
    final tokenStorage = InMemoryTokenStorage('test-token');
    final mockClient = MockHttpClient((request) async {
      return http.Response(
        jsonEncode({
          'id': 'pref-1',
          'preferred_roles': ['Product Designer'],
          'job_type': 'Full-time',
          'work_mode': 'Remote',
          'min_salary': 25000,
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

    final prefController = JobPreferenceController(
      preferenceService: JobPreferenceService(apiClient: apiClient),
      initialPreference: const JobPreference(
        preferredRoles: ['Product Designer'],
        jobType: 'Full-time',
        workMode: 'Remote',
        minSalary: 25000,
        preferredLocations: ['Remote'],
        minMatchThreshold: 85,
      ),
      initialStatus: JobPreferenceStateStatus.loaded,
    );

    await tester.pumpWidget(
      AiJobHunterApp(jobPreferenceController: prefController),
    );

    await tester.pumpWidget(const MaterialApp(home: JobPreferencesPage()));

    expect(find.text('Set Your Pace'), findsOneWidget);
    expect(find.text('Desired Roles'), findsOneWidget);
    expect(find.text('Job Type'), findsOneWidget);
    expect(find.text('Work Mode'), findsOneWidget);
    expect(find.text('Save Preferences'), findsOneWidget);
  });
}
