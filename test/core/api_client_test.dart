import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/network/api_exception.dart';
import 'package:hunter/core/storage/token_storage.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('ApiClient', () {
    test(
      'sends request with Authorization header when token is present',
      () async {
        final tokenStorage = InMemoryTokenStorage('secret-jwt-token');
        late http.BaseRequest capturedRequest;

        final mockClient = MockHttpClient((request) async {
          capturedRequest = request;
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        });

        final apiClient = ApiClient(
          apiConfig: const ApiConfig(baseUrl: 'http://10.0.2.2:8000'),
          tokenStorage: tokenStorage,
          client: mockClient,
        );

        final result = await apiClient.get('/users/me');

        expect(
          capturedRequest.headers['Authorization'],
          equals('Bearer secret-jwt-token'),
        );
        expect(result, equals({'status': 'ok'}));
      },
    );

    test(
      'maps 401 Unauthorized status code to ApiException.unauthorized',
      () async {
        final mockClient = MockHttpClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'Could not validate credentials'}),
            401,
          );
        });

        final apiClient = ApiClient(
          apiConfig: const ApiConfig(),
          client: mockClient,
        );

        expect(
          () async => await apiClient.get('/users/me'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.type, 'type', ApiErrorType.unauthorized)
                .having((e) => e.statusCode, 'statusCode', 401)
                .having(
                  (e) => e.message,
                  'message',
                  'Could not validate credentials',
                ),
          ),
        );
      },
    );

    test(
      'maps 422 Unprocessable Entity to ApiException.validationError',
      () async {
        final mockClient = MockHttpClient((request) async {
          return http.Response(
            jsonEncode({
              'detail': [
                {
                  'loc': ['body', 'email'],
                  'msg': 'field required',
                  'type': 'value_error.missing',
                },
              ],
            }),
            422,
          );
        });

        final apiClient = ApiClient(
          apiConfig: const ApiConfig(),
          client: mockClient,
        );

        expect(
          () async => await apiClient.post('/auth/login', body: {}),
          throwsA(
            isA<ApiException>()
                .having((e) => e.type, 'type', ApiErrorType.validationError)
                .having((e) => e.statusCode, 'statusCode', 422),
          ),
        );
      },
    );

    test('maps 500 status code to ApiException.serverError', () async {
      final mockClient = MockHttpClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        client: mockClient,
      );

      expect(
        () async => await apiClient.get('/health'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.type, 'type', ApiErrorType.serverError)
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });
}
