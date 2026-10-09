class ResumeVersion {
  final String id;
  final String resumeId;
  final String userId;
  final String? jobId;
  final String versionType;
  final String contentText;
  final List<String>? changesMade;
  final List<String>? warnings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ResumeVersion({
    required this.id,
    required this.resumeId,
    required this.userId,
    this.jobId,
    required this.versionType,
    required this.contentText,
    this.changesMade,
    this.warnings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ResumeVersion.fromJson(Map<String, dynamic> json) {
    return ResumeVersion(
      id: json['id'] as String,
      resumeId: json['resume_id'] as String,
      userId: json['user_id'] as String,
      jobId: json['job_id'] as String?,
      versionType: json['version_type'] as String? ?? 'original',
      contentText: json['content_text'] as String? ?? '',
      changesMade: (json['changes_made'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      warnings: (json['warnings'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'resume_id': resumeId,
    'user_id': userId,
    'job_id': jobId,
    'version_type': versionType,
    'content_text': contentText,
    'changes_made': changesMade,
    'warnings': warnings,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
