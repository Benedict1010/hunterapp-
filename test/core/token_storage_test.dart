import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/core/storage/token_storage.dart';

class FakeSecureStorageWrapper implements SecureStorageWrapper {
  final Map<String, String> values = {};
  bool shouldFailRead = false;
  bool shouldFailWrite = false;
  bool shouldFailDelete = false;

  @override
  Future<String?> read(String key) async {
    if (shouldFailRead) {
      throw Exception('Secure storage read failed');
    }
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (shouldFailWrite) {
      throw Exception('Secure storage write failed');
    }
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (shouldFailDelete) {
      throw Exception('Secure storage delete failed');
    }
    values.remove(key);
  }
}

void main() {
  group('InMemoryTokenStorage', () {
    test('stores, retrieves, and clears token', () async {
      final storage = InMemoryTokenStorage();

      expect(await storage.getToken(), isNull);

      await storage.saveToken('test-jwt-token-123');
      expect(await storage.getToken(), equals('test-jwt-token-123'));

      await storage.clearToken();
      expect(await storage.getToken(), isNull);
    });
  });

  group('FileTokenStorage', () {
    test('stores, retrieves, and clears token in temp file', () async {
      final storage = FileTokenStorage(fileName: '.test_hunter_token');

      await storage.clearToken();
      expect(await storage.getToken(), isNull);

      await storage.saveToken('file-jwt-token-xyz');
      expect(await storage.getToken(), equals('file-jwt-token-xyz'));

      await storage.clearToken();
      expect(await storage.getToken(), isNull);
    });
  });

  group('SecureTokenStorage', () {
    late FakeSecureStorageWrapper fakeWrapper;

    setUp(() {
      fakeWrapper = FakeSecureStorageWrapper();
    });

    test('stores, retrieves, and clears token securely', () async {
      final storage = SecureTokenStorage(wrapper: fakeWrapper);

      expect(await storage.getToken(), isNull);

      await storage.saveToken('secure-jwt-token-123');
      expect(await storage.getToken(), equals('secure-jwt-token-123'));
      expect(
        fakeWrapper.values['hunter_auth_token'],
        equals('secure-jwt-token-123'),
      );

      await storage.clearToken();
      expect(await storage.getToken(), isNull);
      expect(fakeWrapper.values.containsKey('hunter_auth_token'), isFalse);
    });

    test('handles whitespace trimming on save and get', () async {
      final storage = SecureTokenStorage(wrapper: fakeWrapper);

      await storage.saveToken('   token-with-whitespace   ');
      expect(await storage.getToken(), equals('token-with-whitespace'));

      await storage.saveToken('   ');
      // Empty whitespace save does not overwrite existing valid token
      expect(await storage.getToken(), equals('token-with-whitespace'));
    });

    test('account switching replaces previous token', () async {
      final storage = SecureTokenStorage(wrapper: fakeWrapper);

      await storage.saveToken('user-1-token');
      expect(await storage.getToken(), equals('user-1-token'));

      await storage.saveToken('user-2-token');
      expect(await storage.getToken(), equals('user-2-token'));
    });

    test(
      'migrates token from legacy FileTokenStorage and deletes legacy file after successful write',
      () async {
        final legacy = FileTokenStorage(fileName: '.test_migration_token');
        await legacy.saveToken('legacy-token-abc');

        final storage = SecureTokenStorage(
          wrapper: fakeWrapper,
          legacyStorage: legacy,
        );

        // Secure storage starts empty
        expect(fakeWrapper.values['hunter_auth_token'], isNull);

        // Reading token triggers migration
        final token = await storage.getToken();

        expect(token, equals('legacy-token-abc'));
        // Verified write in secure storage
        expect(
          fakeWrapper.values['hunter_auth_token'],
          equals('legacy-token-abc'),
        );
        // Legacy file deleted
        expect(await legacy.getToken(), isNull);
      },
    );

    test(
      'preserves legacy token if secure storage write fails during migration',
      () async {
        final legacy = FileTokenStorage(
          fileName: '.test_failed_migration_token',
        );
        await legacy.saveToken('legacy-token-must-stay');

        fakeWrapper.shouldFailWrite = true;

        final storage = SecureTokenStorage(
          wrapper: fakeWrapper,
          legacyStorage: legacy,
        );

        final token = await storage.getToken();

        // Token is returned from legacy fallback
        expect(token, equals('legacy-token-must-stay'));
        // Legacy token file is preserved
        expect(await legacy.getToken(), equals('legacy-token-must-stay'));

        await legacy.clearToken();
      },
    );

    test('secure storage takes precedence over legacy storage', () async {
      final legacy = FileTokenStorage(fileName: '.test_precedence_token');
      await legacy.saveToken('old-legacy-token');

      fakeWrapper.values['hunter_auth_token'] = 'new-secure-token';

      final storage = SecureTokenStorage(
        wrapper: fakeWrapper,
        legacyStorage: legacy,
      );

      expect(await storage.getToken(), equals('new-secure-token'));
      // Legacy storage untouched
      expect(await legacy.getToken(), equals('old-legacy-token'));

      await legacy.clearToken();
    });

    test('logout clears both secure token and legacy token', () async {
      final legacy = FileTokenStorage(fileName: '.test_logout_token');
      await legacy.saveToken('legacy-logout-token');
      fakeWrapper.values['hunter_auth_token'] = 'secure-logout-token';

      final storage = SecureTokenStorage(
        wrapper: fakeWrapper,
        legacyStorage: legacy,
      );

      await storage.clearToken();

      expect(await storage.getToken(), isNull);
      expect(await legacy.getToken(), isNull);
      expect(fakeWrapper.values.containsKey('hunter_auth_token'), isFalse);
    });
  });
}
