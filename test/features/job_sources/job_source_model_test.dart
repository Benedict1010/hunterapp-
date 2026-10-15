import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/features/job_sources/domain/job_source.dart';

void main() {
  group('JobSourceItem Model Test', () {
    test('fromJson and toJson round-trip', () {
      final json = {
        'id': 'src-123',
        'name': 'LinkedIn',
        'base_url': 'https://linkedin.com',
        'description': 'Professional network',
        'is_available': true,
      };

      final item = JobSourceItem.fromJson(json);
      expect(item.id, 'src-123');
      expect(item.name, 'LinkedIn');
      expect(item.baseUrl, 'https://linkedin.com');
      expect(item.description, 'Professional network');
      expect(item.isAvailable, true);

      final output = item.toJson();
      expect(output['id'], 'src-123');
      expect(output['name'], 'LinkedIn');
      expect(output['is_available'], true);
    });

    test('fromJson with missing fields defaults safely', () {
      final item = JobSourceItem.fromJson(const {});
      expect(item.id, '');
      expect(item.name, '');
      expect(item.baseUrl, isNull);
      expect(item.description, isNull);
      expect(item.isAvailable, false);
    });
  });
}
