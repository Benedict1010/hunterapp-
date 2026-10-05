import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hunter/core/network/api_client.dart';
import 'package:hunter/core/storage/token_storage.dart';
import 'package:hunter/features/auth/data/auth_service.dart';
import 'package:hunter/features/auth/presentation/auth_controller.dart';

import '../../core/api_client_test.dart';

void main() {
  group('AuthController', () {
    test(
      'checkSession results in unauthenticated status when no token is saved',
      () async {
        final tokenStorage = InMemoryTokenStorage();
        final apiClient = ApiClient(tokenStorage: tokenStorage);
        final authService = AuthService(
          apiClient: apiClient,
          tokenStorage: tokenStorage,
        );
        final controller = AuthController(authService: authService);

        await controller.checkSession();

        expect(controller.status, equals(AuthStatus.unauthenticated));
        expect(controller.currentUser, isNull);
      },
    );

    test(
      'checkSession restores user and sets authenticated status when token is valid',
      () async {
        final tokenStorage = InMemoryTokenStorage('valid-token');
        final mockClient = MockHttpClient((request) async {
          return http.Response(
            jsonEncode({
              'id': 'usr_valid',
              'email': 'valid@example.com',
              'full_name': 'Valid User',
              'created_at': '2026-09-20T10:00:00Z',
            }),
            200,
          );
        });

        final apiClient = ApiClient(
          tokenStorage: tokenStorage,
          client: mockClient,
        );
        final authService = AuthService(
          apiClient: apiClient,
          tokenStorage: tokenStorage,
        );
        final controller = AuthController(authService: authService);

        await controller.checkSession();

        expect(controller.status, equals(AuthStatus.authenticated));
        expect(controller.currentUser, isNotNull);
        expect(controller.currentUser!.email, equals('valid@example.com'));
      },
    );

    test(
      'checkSession clears invalid token and sets unauthenticated status on 401 response',
      () async {
        final tokenStorage = InMemoryTokenStorage('expired-token');
        final mockClient = MockHttpClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'Could not validate credentials'}),
            401,
          );
        });

        final apiClient = ApiClient(
          tokenStorage: tokenStorage,
          client: mockClient,
        );
        final authService = AuthService(
          apiClient: apiClient,
          tokenStorage: tokenStorage,
        );
        final controller = AuthController(authService: authService);

        await controller.checkSession();

        expect(controller.status, equals(AuthStatus.unauthenticated));
        expect(controller.currentUser, isNull);
        expect(await tokenStorage.getToken(), isNull);
      },
    );

    test('login updates state to authenticated on success', () async {
      final tokenStorage = InMemoryTokenStorage();
      final mockClient = MockHttpClient((request) async {
        if (request.url.path == '/auth/login') {
          return http.Response(
            jsonEncode({
              'access_token': 'newly-logged-in-token',
              'token_type': 'bearer',
            }),
            200,
          );
        } else if (request.url.path == '/users/me') {
          return http.Response(
            jsonEncode({
              'id': 'usr_login',
              'email': 'logged.in@example.com',
              'full_name': 'Logged In User',
              'created_at': '2026-09-20T10:00:00Z',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        tokenStorage: tokenStorage,
        client: mockClient,
      );
      final authService = AuthService(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );
      final controller = AuthController(authService: authService);

      final result = await controller.login(
        'logged.in@example.com',
        'password123',
      );

      expect(result, isTrue);
      expect(controller.status, equals(AuthStatus.authenticated));
      expect(controller.currentUser!.email, equals('logged.in@example.com'));
    });
  });
}
