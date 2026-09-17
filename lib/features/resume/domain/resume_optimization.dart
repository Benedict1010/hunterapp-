class ResumeImprovement {
  const ResumeImprovement(this.title, this.impact, this.description);
  final String title, impact, description;
}

class ResumeOptimization {
  const ResumeOptimization({
    required this.role,
    required this.previousScore,
    required this.newScore,
    required this.sourceFile,
    required this.improvements,
  });
  final String role, sourceFile;
  final int previousScore, newScore;
  final List<ResumeImprovement> improvements;
}

const resumeOptimization = ResumeOptimization(
  role: 'Software Engineer Intern',
  previousScore: 78,
  newScore: 94,
  sourceFile: 'Benedict_Joseph_Resume.pdf',
  improvements: [
    ResumeImprovement(
      'Action-Oriented Verbs',
      'High Impact',
      'Replaced passive descriptions with strong action verbs like “Architected” and “Spearheaded”.',
    ),
    ResumeImprovement(
      'Skill Alignment',
      'Critical Impact',
      'Highlighted React and TypeScript proficiency to match the job description requirements.',
    ),
    ResumeImprovement(
      'Quantified Achievements',
      'Medium Impact',
      'Added metrics to project descriptions, emphasizing a 15% performance improvement.',
    ),
    ResumeImprovement(
      'ATS Keyword Optimization',
      'High Impact',
      'Strategically integrated keywords for distributed systems and CI/CD pipelines.',
    ),
  ],
);
