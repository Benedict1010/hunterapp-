import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/features/jobs/domain/job_match.dart';

void main() {
  group('JobMatch Model Tests', () {
    test('JobMatch parses correctly from JSON', () {
      final json = {
        'id': 'match-1',
        'user_id': 'user-123',
        'resume_id': 'resume-456',
        'job_id': 'job-789',
        'match_score': 87.5,
        'matched_skills': ['Flutter', 'Dart', 'REST API'],
        'missing_skills': ['GraphQL', 'Docker'],
        'explanation': 'Strong overall match for mobile development.',
        'created_at': '2026-03-20T12:00:00Z',
        'updated_at': '2026-03-20T12:00:00Z',
      };

      final match = JobMatch.fromJson(json);

      expect(match.id, 'match-1');
      expect(match.userId, 'user-123');
      expect(match.resumeId, 'resume-456');
      expect(match.jobId, 'job-789');
      expect(match.matchScore, 87.5);
      expect(match.score, 88);
      expect(match.matchedSkills, ['Flutter', 'Dart', 'REST API']);
      expect(match.missingSkills, ['GraphQL', 'Docker']);
      expect(match.explanation, 'Strong overall match for mobile development.');

      final toJson = match.toJson();
      expect(toJson['id'], 'match-1');
      expect(toJson['match_score'], 87.5);
    });

    test('JobMatch handles missing optional explanation', () {
      final json = {
        'id': 'match-2',
        'user_id': 'user-1',
        'resume_id': 'resume-1',
        'job_id': 'job-1',
        'match_score': 95.0,
        'matched_skills': ['Java'],
        'missing_skills': [],
        'created_at': '2026-03-20T12:00:00Z',
        'updated_at': '2026-03-20T12:00:00Z',
      };

      final match = JobMatch.fromJson(json);

      expect(match.explanation, null);
      expect(match.score, 95);
      expect(match.missingSkills, isEmpty);
    });
  });
}
