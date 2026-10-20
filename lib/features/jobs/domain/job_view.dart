class JobView {
  final String id;
  final String userId;
  final String jobId;
  final DateTime createdAt;

  const JobView({
    required this.id,
    required this.userId,
    required this.jobId,
    required this.createdAt,
  });

  factory JobView.fromJson(Map<String, dynamic> json) {
    return JobView(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
