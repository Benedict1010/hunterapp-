import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/core/storage/token_storage.dart';

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
}
