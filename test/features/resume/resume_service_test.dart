import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/resume/data/resume_service.dart';

import '../../core/api_client_test.dart';

void main() {
  group('ResumeService tests', () {
    late InMemoryTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage('test-bearer-token');
    });

    test('listResumes calls GET /resumes and returns list of Resume', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, equals('/resumes'));
        expect(
          request.headers['Authorization'],
          equals('Bearer test-bearer-token'),
        );
        return http.Response(
          jsonEncode([
            {
              'id': 'res_1',
              'user_id': 'usr_1',
              'filename': 'resume1.pdf',
              'file_url': 'url1.pdf',
              'content_text': 'Text 1',
              'is_primary': true,
              'created_at': '2026-09-22T10:00:00Z',
              'updated_at': '2026-09-22T10:00:00Z',
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
      final service = ResumeService(apiClient: apiClient);

      final result = await service.listResumes();

      expect(result.length, equals(1));
      expect(result.first.id, equals('res_1'));
      expect(result.first.filename, equals('resume1.pdf'));
      expect(result.first.isPrimary, isTrue);
    });

    test('getResume calls GET /resumes/{id} and returns Resume', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, equals('/resumes/res_1'));
        return http.Response(
          jsonEncode({
            'id': 'res_1',
            'user_id': 'usr_1',
            'filename': 'resume1.pdf',
            'file_url': 'url1.pdf',
            'content_text': 'Text 1',
            'is_primary': false,
            'created_at': '2026-09-22T10:00:00Z',
            'updated_at': '2026-09-22T10:00:00Z',
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = ResumeService(apiClient: apiClient);

      final resume = await service.getResume('res_1');

      expect(resume.id, equals('res_1'));
      expect(resume.filename, equals('resume1.pdf'));
    });

    test('uploadResume sends multipart POST /resumes', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/resumes'));
        expect(
          request.headers['Authorization'],
          equals('Bearer test-bearer-token'),
        );
        expect(request, isA<http.MultipartRequest>());

        return http.Response(
          jsonEncode({
            'id': 'res_new',
            'user_id': 'usr_1',
            'filename': 'my_doc.pdf',
            'file_url': 'safe.pdf',
            'content_text': 'Extracted content',
            'is_primary': true,
            'created_at': '2026-09-22T10:00:00Z',
            'updated_at': '2026-09-22T10:00:00Z',
          }),
          201,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = ResumeService(apiClient: apiClient);

      final resume = await service.uploadResume(
        filePath: 'dummy/path/my_doc.pdf',
        fileName: 'my_doc.pdf',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      expect(resume.id, equals('res_new'));
      expect(resume.filename, equals('my_doc.pdf'));
    });

    test('updateResume sends multipart PUT /resumes/{id}', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('PUT'));
        expect(request.url.path, equals('/resumes/res_1'));
        return http.Response(
          jsonEncode({
            'id': 'res_1',
            'user_id': 'usr_1',
            'filename': 'updated.pdf',
            'file_url': 'updated.pdf',
            'content_text': 'Updated text',
            'is_primary': false,
            'created_at': '2026-09-22T10:00:00Z',
            'updated_at': '2026-09-22T10:00:00Z',
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = ResumeService(apiClient: apiClient);

      final resume = await service.updateResume(
        'res_1',
        filePath: 'dummy/path/updated.pdf',
        fileName: 'updated.pdf',
        bytes: Uint8List.fromList([5, 6, 7]),
      );

      expect(resume.filename, equals('updated.pdf'));
    });

    test('deleteResume sends DELETE /resumes/{id}', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('DELETE'));
        expect(request.url.path, equals('/resumes/res_1'));
        return http.Response('', 204);
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = ResumeService(apiClient: apiClient);

      await expectLater(service.deleteResume('res_1'), completes);
    });

    test('setPrimary sends PATCH /resumes/{id}/primary', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('PATCH'));
        expect(request.url.path, equals('/resumes/res_1/primary'));
        return http.Response(
          jsonEncode({
            'id': 'res_1',
            'user_id': 'usr_1',
            'filename': 'resume1.pdf',
            'file_url': 'url1.pdf',
            'content_text': 'Text',
            'is_primary': true,
            'created_at': '2026-09-22T10:00:00Z',
            'updated_at': '2026-09-22T10:00:00Z',
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = ResumeService(apiClient: apiClient);

      final resume = await service.setPrimary('res_1');

      expect(resume.isPrimary, isTrue);
    });

    test('extractResume sends POST /resumes/{id}/extract', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/resumes/res_1/extract'));
        return http.Response(
          jsonEncode({
            'id': 'res_1',
            'user_id': 'usr_1',
            'filename': 'resume1.pdf',
            'file_url': 'url1.pdf',
            'content_text': 'Newly extracted text',
            'is_primary': true,
            'created_at': '2026-09-22T10:00:00Z',
            'updated_at': '2026-09-22T10:00:00Z',
          }),
          200,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = ResumeService(apiClient: apiClient);

      final resume = await service.extractResume('res_1');

      expect(resume.contentText, equals('Newly extracted text'));
    });

    test(
      'listVersions sends GET /resumes/{id}/versions and returns list of ResumeVersion',
      () async {
        final mockClient = MockHttpClient((request) async {
          expect(request.url.path, equals('/resumes/res_1/versions'));
          return http.Response(
            jsonEncode([
              {
                'id': 'ver_1',
                'resume_id': 'res_1',
                'user_id': 'usr_1',
                'version_type': 'original',
                'content_text': 'Version text',
                'created_at': '2026-09-24T10:00:00Z',
                'updated_at': '2026-09-24T10:00:00Z',
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
        final service = ResumeService(apiClient: apiClient);

        final versions = await service.listVersions('res_1');

        expect(versions.length, equals(1));
        expect(versions.first.id, equals('ver_1'));
      },
    );

    test('downloadResume sends GET /resumes/{id}/download', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, equals('/resumes/res_1/download'));
        return http.Response.bytes([0x25, 0x50, 0x44, 0x46], 200);
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final service = ResumeService(apiClient: apiClient);

      final bytes = await service.downloadResume('res_1');

      expect(bytes, equals([0x25, 0x50, 0x44, 0x46]));
    });
  });
}
