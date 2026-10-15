class JobPreference {
  final String? id;
  final String? userId;
  final List<String> preferredRoles;
  final String? jobType;
  final String? workMode;
  final int? minSalary;
  final List<String> preferredLocations;
  final int? minMatchThreshold;

  const JobPreference({
    this.id,
    this.userId,
    this.preferredRoles = const [],
    this.jobType,
    this.workMode,
    this.minSalary,
    this.preferredLocations = const [],
    this.minMatchThreshold,
  });

  factory JobPreference.fromJson(Map<String, dynamic> json) {
    return JobPreference(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      preferredRoles:
          (json['preferred_roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      jobType: json['job_type'] as String?,
      workMode: json['work_mode'] as String?,
      minSalary: json['min_salary'] as int?,
      preferredLocations:
          (json['preferred_locations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      minMatchThreshold: json['min_match_threshold'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (userId != null) 'user_id': userId,
    'preferred_roles': preferredRoles,
    'job_type': jobType,
    'work_mode': workMode,
    'min_salary': minSalary,
    'preferred_locations': preferredLocations,
    'min_match_threshold': minMatchThreshold,
  };

  JobPreference copyWith({
    String? id,
    String? userId,
    List<String>? preferredRoles,
    String? jobType,
    String? workMode,
    int? minSalary,
    List<String>? preferredLocations,
    int? minMatchThreshold,
  }) {
    return JobPreference(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      preferredRoles: preferredRoles ?? this.preferredRoles,
      jobType: jobType ?? this.jobType,
      workMode: workMode ?? this.workMode,
      minSalary: minSalary ?? this.minSalary,
      preferredLocations: preferredLocations ?? this.preferredLocations,
      minMatchThreshold: minMatchThreshold ?? this.minMatchThreshold,
    );
  }
}
