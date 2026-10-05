import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/features/auth/domain/auth_token.dart';
import 'package:hunter/features/auth/domain/user.dart';

void main() {
  group('User and AuthToken models', () {
    test('User.fromJson parses FastAPI user object correctly', () {
      final json = {
        'id': 'usr_12345',
        'email': 'jane.doe@example.com',
        'full_name': 'Jane Doe',
        'created_at': '2026-09-20T10:00:00Z',
      };

      final user = User.fromJson(json);

      expect(user.id, equals('usr_12345'));
      expect(user.email, equals('jane.doe@example.com'));
      expect(user.fullName, equals('Jane Doe'));
      expect(user.createdAt, equals(DateTime.parse('2026-09-20T10:00:00Z')));
    });

    test('User.toJson converts to Map matching schema', () {
      final user = User(
        id: 'usr_12345',
        email: 'jane.doe@example.com',
        fullName: 'Jane Doe',
        createdAt: DateTime.parse('2026-09-20T10:00:00Z'),
      );

      final json = user.toJson();

      expect(json['id'], equals('usr_12345'));
      expect(json['email'], equals('jane.doe@example.com'));
      expect(json['full_name'], equals('Jane Doe'));
      expect(json['created_at'], equals('2026-09-20T10:00:00.000Z'));
    });

    test('AuthToken.fromJson parses FastAPI token object correctly', () {
      final json = {
        'access_token': 'jwt-access-token-string',
        'token_type': 'bearer',
      };

      final token = AuthToken.fromJson(json);

      expect(token.accessToken, equals('jwt-access-token-string'));
      expect(token.tokenType, equals('bearer'));
    });
  });
}
