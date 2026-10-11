class JobSkill {
  final String name;
  final double? importance;

  const JobSkill({required this.name, this.importance});

  factory JobSkill.fromJson(Map<String, dynamic> json) {
    return JobSkill(
      name: json['name'] as String? ?? '',
      importance: (json['importance'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (importance != null) 'importance': importance,
  };
}

class Job {
  final String id;
  final String title;
  final String company;
  final String? location;
  final String? description;
  final String? salaryRange;
  final String? jobType;
  final String externalUrl;
  final DateTime? postedAt;
  final String source;
  final List<JobSkill> skills;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    this.location,
    this.description,
    this.salaryRange,
    this.jobType,
    required this.externalUrl,
    this.postedAt,
    required this.source,
    this.skills = const [],
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      location: json['location'] as String?,
      description: json['description'] as String?,
      salaryRange: json['salary_range'] as String?,
      jobType: json['job_type'] as String?,
      externalUrl: json['external_url'] as String? ?? '',
      postedAt: json['posted_at'] != null
          ? DateTime.tryParse(json['posted_at'] as String)
          : null,
      source: json['source'] as String? ?? '',
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((s) => JobSkill.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'company': company,
    'location': location,
    'description': description,
    'salary_range': salaryRange,
    'job_type': jobType,
    'external_url': externalUrl,
    'posted_at': postedAt?.toIso8601String(),
    'source': source,
    'skills': skills.map((s) => s.toJson()).toList(),
  };

  String get compensation => salaryRange ?? 'Not specified';
  String get workMode => jobType ?? 'Not specified';
  String get about => description ?? 'No description available.';
  List<String> get requirements => skills.map((s) => s.name).toList();
  String get locationLabel => location ?? 'Remote / Unspecified';
  String get postedLabel {
    if (postedAt == null) return 'Recently';
    final diff = DateTime.now().difference(postedAt!);
    if (diff.inDays > 0) {
      return 'Posted ${diff.inDays} ${diff.inDays == 1 ? "day" : "days"} ago';
    } else if (diff.inHours > 0) {
      return 'Posted ${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago';
    } else {
      return 'Posted recently';
    }
  }
}

class JobListResponse {
  final List<Job> items;
  final int total;
  final int limit;
  final int offset;

  const JobListResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory JobListResponse.fromJson(Map<String, dynamic> json) {
    return JobListResponse(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => Job.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 20,
      offset: json['offset'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((j) => j.toJson()).toList(),
    'total': total,
    'limit': limit,
    'offset': offset,
  };
}
