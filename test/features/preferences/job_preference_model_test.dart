import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/features/preferences/domain/job_preference.dart';

void main() {
  group('JobPreference Model Test', () {
    test('fromJson and toJson round-trip', () {
      final json = {
        'id': 'pref-123',
        'user_id': 'u-1',
        'preferred_roles': ['Backend Dev', 'Fullstack'],
        'job_type': 'Full-time',
        'work_mode': 'Remote',
        'min_salary': 35000,
        'preferred_locations': ['Bangalore, KA'],
        'min_match_threshold': 80,
      };

      final pref = JobPreference.fromJson(json);
      expect(pref.id, 'pref-123');
      expect(pref.userId, 'u-1');
      expect(pref.preferredRoles, ['Backend Dev', 'Fullstack']);
      expect(pref.jobType, 'Full-time');
      expect(pref.workMode, 'Remote');
      expect(pref.minSalary, 35000);
      expect(pref.preferredLocations, ['Bangalore, KA']);
      expect(pref.minMatchThreshold, 80);

      final output = pref.toJson();
      expect(output['id'], 'pref-123');
      expect(output['job_type'], 'Full-time');
      expect(output['min_salary'], 35000);
    });

    test('copyWith works correctly', () {
      const pref = JobPreference(minSalary: 20000);
      final updated = pref.copyWith(minSalary: 30000, workMode: 'Hybrid');
      expect(updated.minSalary, 30000);
      expect(updated.workMode, 'Hybrid');
    });
  });
}
