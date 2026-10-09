import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/features/resume/data/resume_service.dart';
import 'package:hunter/features/resume/presentation/resume_controller.dart';

import '../../core/api_client_test.dart';

void main() {
  group('ResumeController tests', () {
    test('initial status is initial with empty resumes', () {
      final apiClient = ApiClient(apiConfig: const ApiConfig());
      final service = ResumeService(apiClient: apiClient);
      final controller = ResumeController(resumeService: service);

      expect(controller.status, equals(ResumeStateStatus.initial));
      expect(controller.resumes, isEmpty);
      expect(controller.primaryResume, isNull);
      expect(controller.errorMessage, isNull);
    });

    test('loadResumes updates resumes and identifies primary resume', () async {
      final mockClient = MockHttpClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': 'res_1',
              'user_id': 'usr_1',
              'filename': 'first.pdf',
              'file_url': 'first.pdf',
              'content_text': 'Content 1',
              'is_primary': false,
              'created_at': '2026-09-22T10:00:00Z',
              'updated_at': '2026-09-22T10:00:00Z',
            },
            {
              'id': 'res_2',
              'user_id': 'usr_1',
              'filename': 'second.pdf',
              'file_url': 'second.pdf',
              'content_text': 'Content 2',
              'is_primary': true,
              'created_at': '2026-09-22T11:00:00Z',
              'updated_at': '2026-09-22T11:00:00Z',
            },
          ]),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        client: mockClient,
      );
      final service = ResumeService(apiClient: apiClient);
      final controller = ResumeController(resumeService: service);

      await controller.loadResumes();

      expect(controller.status, equals(ResumeStateStatus.loaded));
      expect(controller.resumes.length, equals(2));
      expect(controller.primaryResume?.id, equals('res_2'));
    });

    test('uploadResume handles success and reloads resumes', () async {
      final mockClient = MockHttpClient((request) async {
        if (request.method == 'POST' && request.url.path == '/resumes') {
          return http.Response(
            jsonEncode({
              'id': 'res_uploaded',
              'user_id': 'usr_1',
              'filename': 'new.pdf',
              'file_url': 'new.pdf',
              'content_text': 'Extracted',
              'is_primary': true,
              'created_at': '2026-09-22T12:00:00Z',
              'updated_at': '2026-09-22T12:00:00Z',
            }),
            201,
          );
        }
        return http.Response(
          jsonEncode([
            {
              'id': 'res_uploaded',
              'user_id': 'usr_1',
              'filename': 'new.pdf',
              'file_url': 'new.pdf',
              'content_text': 'Extracted',
              'is_primary': true,
              'created_at': '2026-09-22T12:00:00Z',
              'updated_at': '2026-09-22T12:00:00Z',
            },
          ]),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        client: mockClient,
      );
      final service = ResumeService(apiClient: apiClient);
      final controller = ResumeController(resumeService: service);

      final uploaded = await controller.uploadResume(
        filePath: 'test.pdf',
        fileName: 'new.pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      expect(uploaded, isNotNull);
      expect(uploaded?.id, equals('res_uploaded'));
      expect(controller.resumes.length, equals(1));
    });

    test('uploadResume handles error and sets error state', () async {
      final mockClient = MockHttpClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'File size exceeds limit'}),
          413,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        client: mockClient,
      );
      final service = ResumeService(apiClient: apiClient);
      final controller = ResumeController(resumeService: service);

      final result = await controller.uploadResume(
        filePath: 'big.pdf',
        fileName: 'big.pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      expect(result, isNull);
      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, contains('File size exceeds limit'));
    });

    test('deleteResume handles success', () async {
      final mockClient = MockHttpClient((request) async {
        if (request.method == 'DELETE') {
          return http.Response('', 204);
        }
        return http.Response(jsonEncode([]), 200);
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        client: mockClient,
      );
      final service = ResumeService(apiClient: apiClient);
      final controller = ResumeController(resumeService: service);

      final deleted = await controller.deleteResume('res_1');

      expect(deleted, isTrue);
      expect(controller.resumes, isEmpty);
    });
  });
}
