class Job {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.workMode,
    required this.compensation,
    required this.postedLabel,
    required this.about,
    required this.requirements,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String workMode;
  final String compensation;
  final String postedLabel;
  final String about;
  final List<String> requirements;
}

class JobMatch {
  const JobMatch({
    required this.job,
    required this.score,
    required this.rationale,
    required this.tags,
  });

  final Job job;
  final int score;
  final String rationale;
  final List<String> tags;
}

class SkillMatch {
  const SkillMatch(this.name, this.score);
  final String name;
  final int score;
}
