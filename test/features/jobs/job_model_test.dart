import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/features/jobs/domain/job.dart';

void main() {
  group('Job Model Tests', () {
    test('JobSkill parses correctly from valid JSON', () {
      final json = {'name': 'Flutter', 'importance': 0.9};
      final skill = JobSkill.fromJson(json);

      expect(skill.name, 'Flutter');
      expect(skill.importance, 0.9);

      final toJson = skill.toJson();
      expect(toJson['name'], 'Flutter');
      expect(toJson['importance'], 0.9);
    });

    test('JobSkill handles missing importance gracefully', () {
      final json = {'name': 'Dart'};
      final skill = JobSkill.fromJson(json);

      expect(skill.name, 'Dart');
      expect(skill.importance, null);
    });

    test('Job parses correctly from complete JSON', () {
      final json = {
        'id': 'job-123',
        'title': 'Senior Flutter Engineer',
        'company': 'Tech Corp',
        'location': 'Bangalore, India',
        'description': 'Build high performance Flutter apps.',
        'salary_range': '₹15L - ₹25L',
        'job_type': 'Full-time',
        'external_url': 'https://techcorp.com/jobs/123',
        'posted_at': '2026-03-20T10:00:00Z',
        'source': 'LinkedIn',
        'skills': [
          {'name': 'Flutter', 'importance': 1.0},
          {'name': 'Dart', 'importance': 0.8},
        ],
      };

      final job = Job.fromJson(json);

      expect(job.id, 'job-123');
      expect(job.title, 'Senior Flutter Engineer');
      expect(job.company, 'Tech Corp');
      expect(job.location, 'Bangalore, India');
      expect(job.description, 'Build high performance Flutter apps.');
      expect(job.salaryRange, '₹15L - ₹25L');
      expect(job.jobType, 'Full-time');
      expect(job.externalUrl, 'https://techcorp.com/jobs/123');
      expect(job.postedAt, DateTime.utc(2026, 3, 20, 10, 0, 0));
      expect(job.source, 'LinkedIn');
      expect(job.skills.length, 2);
      expect(job.compensation, '₹15L - ₹25L');
      expect(job.workMode, 'Full-time');
      expect(job.requirements, ['Flutter', 'Dart']);

      final toJson = job.toJson();
      expect(toJson['id'], 'job-123');
      expect(toJson['source'], 'LinkedIn');
    });

    test('Job handles nullable/optional fields', () {
      final json = {
        'id': 'job-456',
        'title': 'Junior Developer',
        'company': 'Startup Inc',
        'external_url': 'https://startup.io/jobs',
        'source': 'Unstop',
      };

      final job = Job.fromJson(json);

      expect(job.id, 'job-456');
      expect(job.location, null);
      expect(job.description, null);
      expect(job.salaryRange, null);
      expect(job.jobType, null);
      expect(job.postedAt, null);
      expect(job.skills, isEmpty);
      expect(job.compensation, 'Not specified');
      expect(job.workMode, 'Not specified');
      expect(job.about, 'No description available.');
      expect(job.locationLabel, 'Remote / Unspecified');
      expect(job.postedLabel, 'Recently');
    });

    test('JobListResponse parses list correctly', () {
      final json = {
        'items': [
          {
            'id': 'j1',
            'title': 'Dev 1',
            'company': 'C1',
            'external_url': 'https://c1.com',
            'source': 'Mock',
            'skills': [],
          },
          {
            'id': 'j2',
            'title': 'Dev 2',
            'company': 'C2',
            'external_url': 'https://c2.com',
            'source': 'Mock',
            'skills': [],
          },
        ],
        'total': 2,
        'limit': 20,
        'offset': 0,
      };

      final response = JobListResponse.fromJson(json);

      expect(response.items.length, 2);
      expect(response.total, 2);
      expect(response.limit, 20);
      expect(response.offset, 0);
      expect(response.items.first.id, 'j1');
    });
  });
}
