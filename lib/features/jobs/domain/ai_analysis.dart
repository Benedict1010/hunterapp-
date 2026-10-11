class AiAnalysis {
  final String summary;
  final List<String> strengths;
  final List<String> missingSkills;
  final List<String> recommendations;
  final double? rawScore;

  const AiAnalysis({
    required this.summary,
    required this.strengths,
    required this.missingSkills,
    required this.recommendations,
    this.rawScore,
  });

  factory AiAnalysis.fromJson(Map<String, dynamic> json) {
    return AiAnalysis(
      summary: json['summary'] as String? ?? '',
      strengths:
          (json['strengths'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          const [],
      missingSkills:
          (json['missing_skills'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          const [],
      recommendations:
          (json['recommendations'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          const [],
      rawScore: (json['raw_score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'strengths': strengths,
    'missing_skills': missingSkills,
    'recommendations': recommendations,
    if (rawScore != null) 'raw_score': rawScore,
  };
}
