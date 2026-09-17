enum ApplicationStatus { applied, interviewing, offered }

class JobApplication {
  const JobApplication({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.date,
    required this.matchScore,
    required this.status,
  });
  final String id, title, company, location, date;
  final int matchScore;
  final ApplicationStatus status;
}

enum ApplicationStageStatus { completed, current, upcoming }

class ApplicationTimelineStage {
  const ApplicationTimelineStage({
    required this.title,
    required this.date,
    required this.status,
  });
  final String title;
  final String date;
  final ApplicationStageStatus status;
}

class ApplicationDetail {
  const ApplicationDetail({
    required this.application,
    required this.employmentType,
    required this.updatedAt,
    required this.timeline,
  });
  final JobApplication application;
  final String employmentType;
  final String updatedAt;
  final List<ApplicationTimelineStage> timeline;
}
