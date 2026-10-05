import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hunter/core/config/api_config.dart';
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/auth/data/auth_service.dart';

import '../../core/api_client_test.dart';

void main() {
  group('AuthService', () {
    late InMemoryTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage();
    });

    test('register calls POST /auth/register and returns User', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.path, equals('/auth/register'));
        return http.Response(
          jsonEncode({
            'id': 'usr_999',
            'email': 'new.user@example.com',
            'full_name': 'New User',
            'created_at': '2026-09-20T12:00:00Z',
          }),
          201,
        );
      });

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
        client: mockClient,
      );

      final authService = AuthService(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      final user = await authService.register(
        email: 'new.user@example.com',
        password: 'password123',
        fullName: 'New User',
      );

      expect(user.id, equals('usr_999'));
      expect(user.email, equals('new.user@example.com'));
      expect(user.fullName, equals('New User'));
    });

    test(
      'login calls POST /auth/login, returns AuthToken and stores access token',
      () async {
        final mockClient = MockHttpClient((request) async {
          expect(request.url.path, equals('/auth/login'));
          return http.Response(
            jsonEncode({
              'access_token': 'my-secret-jwt-token',
              'token_type': 'bearer',
            }),
            200,
          );
        });

        final apiClient = ApiClient(
          apiConfig: const ApiConfig(),
          tokenStorage: tokenStorage,
          client: mockClient,
        );

        final authService = AuthService(
          apiClient: apiClient,
          tokenStorage: tokenStorage,
        );

        final token = await authService.login(
          email: 'user@example.com',
          password: 'password123',
        );

        expect(token.accessToken, equals('my-secret-jwt-token'));
        expect(await tokenStorage.getToken(), equals('my-secret-jwt-token'));
      },
    );

    test(
      'getCurrentUser calls GET /users/me with stored bearer token',
      () async {
        await tokenStorage.saveToken('my-secret-jwt-token');

        final mockClient = MockHttpClient((request) async {
          expect(request.url.path, equals('/users/me'));
          expect(
            request.headers['Authorization'],
            equals('Bearer my-secret-jwt-token'),
          );
          return http.Response(
            jsonEncode({
              'id': 'usr_100',
              'email': 'user@example.com',
              'full_name': 'Existing User',
              'created_at': '2026-09-20T10:00:00Z',
            }),
            200,
          );
        });

        final apiClient = ApiClient(
          apiConfig: const ApiConfig(),
          tokenStorage: tokenStorage,
          client: mockClient,
        );

        final authService = AuthService(
          apiClient: apiClient,
          tokenStorage: tokenStorage,
        );

        final user = await authService.getCurrentUser();

        expect(user.id, equals('usr_100'));
        expect(user.email, equals('user@example.com'));
      },
    );

    test('logout clears stored token', () async {
      await tokenStorage.saveToken('token-to-delete');

      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
      );

      final authService = AuthService(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );

      await authService.logout();

      expect(await tokenStorage.getToken(), isNull);
    });
  });
}
