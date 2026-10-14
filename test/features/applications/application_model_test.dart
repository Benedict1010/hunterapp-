import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/features/applications/domain/job_application.dart';

void main() {
  group('Application Model Tests', () {
    test('JobSummary parses correctly from JSON', () {
      final json = {
        'id': 'job-1',
        'title': 'Flutter Developer',
        'company': 'Tech Corp',
        'location': 'Remote',
      };

      final summary = JobSummary.fromJson(json);

      expect(summary.id, 'job-1');
      expect(summary.title, 'Flutter Developer');
      expect(summary.company, 'Tech Corp');
      expect(summary.location, 'Remote');
    });

    test('Application parses correctly from JSON', () {
      final json = {
        'id': 'app-123',
        'user_id': 'usr-1',
        'job_id': 'job-1',
        'resume_version_id': 'ver-1',
        'status': 'interview',
        'application_url': 'https://techcorp.com/careers/app-123',
        'source': 'linkedin',
        'applied_at': '2026-03-20T10:00:00Z',
        'created_at': '2026-03-20T10:00:00Z',
        'updated_at': '2026-03-20T12:00:00Z',
        'job': {
          'id': 'job-1',
          'title': 'Senior Engineer',
          'company': 'Tech Corp',
          'location': 'San Francisco, CA',
        },
      };

      final app = Application.fromJson(json);

      expect(app.id, 'app-123');
      expect(app.userId, 'usr-1');
      expect(app.status, ApplicationStatus.interview);
      expect(app.title, 'Senior Engineer');
      expect(app.company, 'Tech Corp');
      expect(app.location, 'San Francisco, CA');
      expect(app.source, 'linkedin');
      expect(app.applicationUrl, 'https://techcorp.com/careers/app-123');

      final toJson = app.toJson();
      expect(toJson['id'], 'app-123');
      expect(toJson['status'], 'interview');
    });

    test('ApplicationTimelineEvent parses correctly from JSON', () {
      final json = {
        'id': 'tm-1',
        'application_id': 'app-123',
        'status': 'applied',
        'note': 'Application submitted via LinkedIn',
        'created_at': '2026-03-20T10:00:00Z',
        'updated_at': '2026-03-20T10:00:00Z',
      };

      final event = ApplicationTimelineEvent.fromJson(json);

      expect(event.id, 'tm-1');
      expect(event.applicationId, 'app-123');
      expect(event.status, ApplicationStatus.applied);
      expect(event.note, 'Application submitted via LinkedIn');
      expect(event.title, 'Application submitted via LinkedIn');
    });

    test('ApplicationExternalLink parses correctly from JSON', () {
      final json = {
        'application_id': 'app-123',
        'application_url': 'https://example.com/apply',
        'source': 'unstop',
      };

      final link = ApplicationExternalLink.fromJson(json);

      expect(link.applicationId, 'app-123');
      expect(link.applicationUrl, 'https://example.com/apply');
      expect(link.source, 'unstop');
    });
  });
}
