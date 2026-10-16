class AiTailoring {
  final String tailoredResume;
  final List<String> changesMade;
  final List<String> warnings;

  const AiTailoring({
    required this.tailoredResume,
    required this.changesMade,
    required this.warnings,
  });

  factory AiTailoring.fromJson(Map<String, dynamic> json) {
    return AiTailoring(
      tailoredResume: json['tailored_resume'] as String? ?? '',
      changesMade: (json['changes_made'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      warnings: (json['warnings'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
    );
  }
}
