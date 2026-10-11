class JobMatch {
  final String id;
  final String userId;
  final String resumeId;
  final String jobId;
  final double matchScore;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final String? explanation;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobMatch({
    required this.id,
    required this.userId,
    required this.resumeId,
    required this.jobId,
    required this.matchScore,
    required this.matchedSkills,
    required this.missingSkills,
    this.explanation,
    required this.createdAt,
    required this.updatedAt,
  });

  int get score => matchScore.round();

  factory JobMatch.fromJson(Map<String, dynamic> json) {
    return JobMatch(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      resumeId: json['resume_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.0,
      matchedSkills:
          (json['matched_skills'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          const [],
      missingSkills:
          (json['missing_skills'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          const [],
      explanation: json['explanation'] as String?,
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
    'user_id': userId,
    'resume_id': resumeId,
    'job_id': jobId,
    'match_score': matchScore,
    'matched_skills': matchedSkills,
    'missing_skills': missingSkills,
    'explanation': explanation,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
