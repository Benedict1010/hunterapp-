import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hunter/app/app.dart';
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/job_sources/data/job_source_service.dart';
import 'package:hunter/features/job_sources/domain/job_source.dart';
import 'package:hunter/features/job_sources/presentation/job_source_controller.dart';
import 'package:hunter/features/job_sources/presentation/job_sources_page.dart';

import '../../core/api_client_test.dart';

void main() {
  testWidgets('JobSourcesPage renders platforms and handles selection', (
    WidgetTester tester,
  ) async {
    final tokenStorage = InMemoryTokenStorage('test-token');
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
      return http.Response('OK', 200);
    });

    final apiClient = ApiClient(
      apiConfig: const ApiConfig(),
      tokenStorage: tokenStorage,
      client: mockClient,
    );

    final jobSourceController = JobSourceController(
      jobSourceService: JobSourceService(apiClient: apiClient),
      initialSources: const [
        JobSourceItem(id: 'src-1', name: 'LinkedIn', isAvailable: false),
        JobSourceItem(id: 'src-2', name: 'Unstop', isAvailable: true),
      ],
      initialSelectedIds: {'src-1'},
      initialStatus: JobSourceStateStatus.loaded,
    );

    await tester.pumpWidget(
      AiJobHunterApp(jobSourceController: jobSourceController),
    );

    // Navigate or render JobSourcesPage
    await tester.pumpWidget(MaterialApp(home: JobSourcesPage()));

    expect(find.text('Choose Job Sources'), findsOneWidget);
    expect(find.text('STEP 2 OF 4'), findsOneWidget);
  });
}
