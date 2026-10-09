import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/features/resume/domain/resume.dart';
import 'package:hunter/features/resume/domain/resume_version.dart';

void main() {
  group('Resume model tests', () {
    test('Resume.fromJson parses full FastAPI resume object correctly', () {
      final json = {
        'id': 'res_123',
        'user_id': 'usr_456',
        'filename': 'my_resume.pdf',
        'file_url': 'safe_path.pdf',
        'content_text': 'Extracted resume text content',
        'is_primary': true,
        'created_at': '2026-09-22T10:00:00Z',
        'updated_at': '2026-09-22T10:00:00Z',
      };

      final resume = Resume.fromJson(json);

      expect(resume.id, equals('res_123'));
      expect(resume.userId, equals('usr_456'));
      expect(resume.filename, equals('my_resume.pdf'));
      expect(resume.fileUrl, equals('safe_path.pdf'));
      expect(resume.contentText, equals('Extracted resume text content'));
      expect(resume.isPrimary, isTrue);
      expect(resume.createdAt, equals(DateTime.parse('2026-09-22T10:00:00Z')));
      expect(resume.updatedAt, equals(DateTime.parse('2026-09-22T10:00:00Z')));
    });

    test('Resume.fromJson handles null optional fields gracefully', () {
      final json = {
        'id': 'res_124',
        'user_id': 'usr_456',
        'filename': 'resume.docx',
        'file_url': null,
        'content_text': null,
        'is_primary': false,
        'created_at': '2026-09-22T10:00:00Z',
        'updated_at': '2026-09-22T10:00:00Z',
      };

      final resume = Resume.fromJson(json);

      expect(resume.id, equals('res_124'));
      expect(resume.fileUrl, isNull);
      expect(resume.contentText, isNull);
      expect(resume.isPrimary, isFalse);
    });

    test('Resume.toJson converts model back to JSON map', () {
      final resume = Resume(
        id: 'res_125',
        userId: 'usr_789',
        filename: 'test.pdf',
        fileUrl: 'url.pdf',
        contentText: 'Sample',
        isPrimary: true,
        createdAt: DateTime.parse('2026-09-22T10:00:00Z'),
        updatedAt: DateTime.parse('2026-09-22T10:00:00Z'),
      );

      final json = resume.toJson();

      expect(json['id'], equals('res_125'));
      expect(json['user_id'], equals('usr_789'));
      expect(json['filename'], equals('test.pdf'));
      expect(json['is_primary'], isTrue);
    });
  });

  group('ResumeVersion model tests', () {
    test('ResumeVersion.fromJson parses full version object correctly', () {
      final json = {
        'id': 'ver_1',
        'resume_id': 'res_123',
        'user_id': 'usr_456',
        'job_id': 'job_789',
        'version_type': 'tailored',
        'content_text': 'Tailored text',
        'changes_made': ['Added skill A', 'Refactored summary'],
        'warnings': ['Missing skill B'],
        'created_at': '2026-09-24T10:00:00Z',
        'updated_at': '2026-09-24T10:00:00Z',
      };

      final version = ResumeVersion.fromJson(json);

      expect(version.id, equals('ver_1'));
      expect(version.resumeId, equals('res_123'));
      expect(version.userId, equals('usr_456'));
      expect(version.jobId, equals('job_789'));
      expect(version.versionType, equals('tailored'));
      expect(version.contentText, equals('Tailored text'));
      expect(version.changesMade, contains('Added skill A'));
      expect(version.warnings, contains('Missing skill B'));
    });

    test('ResumeVersion.fromJson handles null lists gracefully', () {
      final json = {
        'id': 'ver_2',
        'resume_id': 'res_123',
        'user_id': 'usr_456',
        'job_id': null,
        'version_type': 'original',
        'content_text': 'Original text',
        'changes_made': null,
        'warnings': null,
        'created_at': '2026-09-24T10:00:00Z',
        'updated_at': '2026-09-24T10:00:00Z',
      };

      final version = ResumeVersion.fromJson(json);

      expect(version.id, equals('ver_2'));
      expect(version.jobId, isNull);
      expect(version.changesMade, isNull);
      expect(version.warnings, isNull);
    });
  });
}
