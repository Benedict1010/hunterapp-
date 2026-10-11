import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/features/jobs/domain/ai_analysis.dart';

void main() {
  group('AiAnalysis Model Tests', () {
    test('AiAnalysis parses correctly from JSON', () {
      final json = {
        'summary': 'Candidate is a great fit for senior frontend role.',
        'strengths': [
          '5+ years Flutter experience',
          'Solid state management skills',
        ],
        'missing_skills': ['CI/CD pipeline configuration'],
        'recommendations': [
          'Highlight mobile app architecture in projects section.',
          'Mention automated testing experience.',
        ],
        'raw_score': 92.0,
      };

      final analysis = AiAnalysis.fromJson(json);

      expect(
        analysis.summary,
        'Candidate is a great fit for senior frontend role.',
      );
      expect(analysis.strengths.length, 2);
      expect(analysis.missingSkills, ['CI/CD pipeline configuration']);
      expect(analysis.recommendations.length, 2);
      expect(analysis.rawScore, 92.0);

      final toJson = analysis.toJson();
      expect(toJson['summary'], contains('great fit'));
      expect(toJson['raw_score'], 92.0);
    });

    test('AiAnalysis handles empty or missing lists', () {
      final json = {'summary': 'Basic match.'};

      final analysis = AiAnalysis.fromJson(json);

      expect(analysis.summary, 'Basic match.');
      expect(analysis.strengths, isEmpty);
      expect(analysis.missingSkills, isEmpty);
      expect(analysis.recommendations, isEmpty);
      expect(analysis.rawScore, null);
    });
  });
}
