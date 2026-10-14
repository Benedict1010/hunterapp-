enum ApplicationStatus {
  applied,
  viewed,
  interview,
  offer,
  rejected,
  withdrawn;

  String get value => name;

  static ApplicationStatus fromString(String status) {
    switch (status.toLowerCase().trim()) {
      case 'applied':
        return ApplicationStatus.applied;
      case 'viewed':
        return ApplicationStatus.viewed;
      case 'interview':
      case 'interviewing':
        return ApplicationStatus.interview;
      case 'offer':
      case 'offered':
        return ApplicationStatus.offer;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'withdrawn':
        return ApplicationStatus.withdrawn;
      default:
        return ApplicationStatus.applied;
    }
  }

  String get label {
    switch (this) {
      case ApplicationStatus.applied:
        return 'Applied';
      case ApplicationStatus.viewed:
        return 'Viewed';
      case ApplicationStatus.interview:
        return 'Interviewing';
      case ApplicationStatus.offer:
        return 'Offered';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

class JobSummary {
  final String id;
  final String title;
  final String company;
  final String? location;

  const JobSummary({
    required this.id,
    required this.title,
    required this.company,
    this.location,
  });

  factory JobSummary.fromJson(Map<String, dynamic> json) {
    return JobSummary(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'company': company,
    if (location != null) 'location': location,
  };
}

class Application {
  final String id;
  final String userId;
  final String jobId;
  final String resumeVersionId;
  final ApplicationStatus status;
  final String? applicationUrl;
  final String? source;
  final DateTime? appliedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final JobSummary? job;
  final int matchScore;

  const Application({
    required this.id,
    required this.userId,
    required this.jobId,
    required this.resumeVersionId,
    required this.status,
    this.applicationUrl,
    this.source,
    this.appliedAt,
    required this.createdAt,
    required this.updatedAt,
    this.job,
    this.matchScore = 85,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      resumeVersionId: json['resume_version_id'] as String? ?? '',
      status: ApplicationStatus.fromString(
        json['status'] as String? ?? 'applied',
      ),
      applicationUrl: json['application_url'] as String?,
      source: json['source'] as String?,
      appliedAt: json['applied_at'] != null
          ? DateTime.tryParse(json['applied_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      job: json['job'] != null
          ? JobSummary.fromJson(json['job'] as Map<String, dynamic>)
          : null,
      matchScore: json['match_score'] as int? ?? 85,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'job_id': jobId,
    'resume_version_id': resumeVersionId,
    'status': status.value,
    'application_url': applicationUrl,
    'source': source,
    'applied_at': appliedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (job != null) 'job': job!.toJson(),
  };

  String get title => job?.title ?? 'Job Application';
  String get company => job?.company ?? 'Company';
  String get location => job?.location ?? 'Remote / Unspecified';
  String get date {
    final target = appliedAt ?? createdAt;
    final month = switch (target.month) {
      1 => 'Jan',
      2 => 'Feb',
      3 => 'Mar',
      4 => 'Apr',
      5 => 'May',
      6 => 'Jun',
      7 => 'Jul',
      8 => 'Aug',
      9 => 'Sep',
      10 => 'Oct',
      11 => 'Nov',
      12 => 'Dec',
      _ => 'Jan',
    };
    return '$month ${target.day}';
  }
}

class ApplicationTimelineEvent {
  final String id;
  final String applicationId;
  final ApplicationStatus status;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ApplicationTimelineEvent({
    required this.id,
    required this.applicationId,
    required this.status,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApplicationTimelineEvent.fromJson(Map<String, dynamic> json) {
    return ApplicationTimelineEvent(
      id: json['id'] as String? ?? '',
      applicationId: json['application_id'] as String? ?? '',
      status: ApplicationStatus.fromString(
        json['status'] as String? ?? 'applied',
      ),
      note: json['note'] as String?,
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
    'application_id': applicationId,
    'status': status.value,
    'note': note,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  String get title => note ?? 'Status changed to ${status.label}';
  String get date {
    final month = switch (createdAt.month) {
      1 => 'Jan',
      2 => 'Feb',
      3 => 'Mar',
      4 => 'Apr',
      5 => 'May',
      6 => 'Jun',
      7 => 'Jul',
      8 => 'Aug',
      9 => 'Sep',
      10 => 'Oct',
      11 => 'Nov',
      12 => 'Dec',
      _ => 'Jan',
    };
    return '$month ${createdAt.day}, ${createdAt.year}';
  }
}

class ApplicationExternalLink {
  final String applicationId;
  final String applicationUrl;
  final String? source;

  const ApplicationExternalLink({
    required this.applicationId,
    required this.applicationUrl,
    this.source,
  });

  factory ApplicationExternalLink.fromJson(Map<String, dynamic> json) {
    return ApplicationExternalLink(
      applicationId: json['application_id'] as String? ?? '',
      applicationUrl: json['application_url'] as String? ?? '',
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'application_id': applicationId,
    'application_url': applicationUrl,
    'source': source,
  };
}
