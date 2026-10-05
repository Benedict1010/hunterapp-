import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/core/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('uses default base URL when not specified', () {
      const config = ApiConfig();
      expect(config.baseUrl, equals('http://10.0.2.2:8000'));
    });

    test('accepts custom base URL', () {
      const config = ApiConfig(baseUrl: 'https://api.example.com');
      expect(config.baseUrl, equals('https://api.example.com'));
    });

    test('formats endpoint paths correctly without double slashes', () {
      const config = ApiConfig(baseUrl: 'http://10.0.2.2:8000/');
      expect(
        config.endpoint('/auth/login'),
        equals('http://10.0.2.2:8000/auth/login'),
      );
      expect(
        config.endpoint('auth/login'),
        equals('http://10.0.2.2:8000/auth/login'),
      );
    });

    test('builds Uri with optional query parameters', () {
      const config = ApiConfig(baseUrl: 'http://10.0.2.2:8000');
      final uri = config.uri('/jobs', {'limit': 10, 'search': 'flutter'});

      expect(
        uri.toString(),
        equals('http://10.0.2.2:8000/jobs?limit=10&search=flutter'),
      );
    });
  });
}
