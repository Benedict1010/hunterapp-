import 'package:flutter/material.dart';

import '../../../app/job_scope.dart';
import '../../../app/resume_scope.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_chips.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/content_widgets.dart';
import '../domain/ai_analysis.dart';
import '../domain/job.dart';
import '../domain/job_match.dart';
import 'job_controller.dart';

class JobDetailPage extends StatefulWidget {
  const JobDetailPage({super.key});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  var saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initJobDetail();
    });
  }

  void _initJobDetail() {
    final jobId = ModalRoute.of(context)?.settings.arguments as String?;
    final jobController = JobScope.maybeOf(context);
    final resumeController = ResumeScope.maybeOf(context);

    if (jobController == null) return;

    if (jobId != null && jobId.isNotEmpty) {
      jobController.loadJobDetail(jobId).then((job) {
        if (job != null && resumeController != null) {
          final primaryResume = resumeController.primaryResume;
          if (primaryResume != null) {
            jobController.calculateMatch(
              jobId: job.id,
              resumeId: primaryResume.id,
            );
          }
        }
      });
    } else if (jobController.selectedJob != null) {
      final job = jobController.selectedJob!;
      final primaryResume = resumeController?.primaryResume;
      if (primaryResume != null && jobController.currentMatch == null) {
        jobController.calculateMatch(jobId: job.id, resumeId: primaryResume.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobController = JobScope.maybeOf(context);
    final resumeController = ResumeScope.maybeOf(context);
    final primaryResume = resumeController?.primaryResume;

    final job = jobController?.selectedJob;
    final match = jobController?.currentMatch;
    final analysis = jobController?.currentAnalysis;

    return AppShell(
      navigationVariant: AppNavigationVariant.hunter,
      selectedIndex: 1,
      child: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                if (jobController != null && jobController.isLoadingDetail) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (job == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.work_outlined,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            jobController?.errorMessage ??
                                'Job details not found.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          tooltip: 'Back',
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {},
                          tooltip: 'Share job',
                          icon: const Icon(Icons.share_outlined),
                        ),
                        IconButton(
                          onPressed: () => setState(() => saved = !saved),
                          tooltip: saved ? 'Remove bookmark' : 'Bookmark job',
                          icon: Icon(
                            saved ? Icons.bookmark : Icons.bookmark_border,
                            color: saved ? AppColors.primary : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: AppRadii.large,
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      job.title,
                      style: Theme.of(
                        context,
                      ).textTheme.displaySmall?.copyWith(fontFamily: 'serif'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job.company}  •  ${job.postedLabel}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TagChip(label: job.locationLabel),
                        if (job.jobType != null && job.jobType!.isNotEmpty)
                          TagChip(
                            label: job.jobType!,
                            color: AppColors.successSoft,
                          ),
                        if (job.salaryRange != null &&
                            job.salaryRange!.isNotEmpty)
                          TagChip(label: job.salaryRange!),
                        if (job.source.isNotEmpty)
                          TagChip(label: 'Source: ${job.source}'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // MATCH SCORE SECTION
                    _buildMatchSection(
                      context: context,
                      jobController: jobController,
                      job: job,
                      primaryResumeId: primaryResume?.id,
                      match: match,
                    ),

                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'About the Role',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      job.about,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    if (job.skills.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Required Skills',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _Checklist(items: job.skills.map((s) => s.name).toList()),
                    ],

                    if (match != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Skills Breakdown',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _SkillsBreakdown(match: match),
                    ],

                    // AI ANALYSIS SECTION
                    const SizedBox(height: AppSpacing.lg),
                    _buildAiAnalysisSection(
                      context: context,
                      jobController: jobController,
                      job: job,
                      primaryResumeId: primaryResume?.id,
                      analysis: analysis,
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                );
              },
            ),
          ),
          if (job != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryOutlinedButton(
                      label: 'Tailor Resume',
                      leading: const Icon(Icons.auto_awesome_outlined),
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.optimizationReady),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Apply Now',
                      onPressed: () {
                        final url = job.externalUrl;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              url.isNotEmpty
                                  ? 'Opening application page: $url'
                                  : 'External application integration will be implemented later.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchSection({
    required BuildContext context,
    required JobController? jobController,
    required Job job,
    required String? primaryResumeId,
    required JobMatch? match,
  }) {
    if (match != null) {
      return MatchScoreCard(
        score: match.score,
        label: 'AI Skill Analysis',
        message: match.explanation != null && match.explanation!.isNotEmpty
            ? '“${match.explanation}”'
            : 'Match calculated based on your primary resume and job requirements.',
      );
    }

    if (primaryResumeId == null) {
      return const MatchScoreCard(
        score: 94,
        label: 'AI Skill Analysis',
        message:
            'Upload a resume to see your personalized match score and skill analysis.',
      );
    }

    return AppSurface(
      child: OutlinedButton.icon(
        onPressed: () => jobController?.calculateMatch(
          jobId: job.id,
          resumeId: primaryResumeId,
        ),
        icon: const Icon(Icons.analytics_outlined),
        label: const Text('Calculate Skill Match'),
      ),
    );
  }

  Widget _buildAiAnalysisSection({
    required BuildContext context,
    required JobController? jobController,
    required Job job,
    required String? primaryResumeId,
    required AiAnalysis? analysis,
  }) {
    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'AI Match Analysis',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (jobController != null && jobController.isAnalyzing) ...[
            const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: AppSpacing.sm),
                Text('Running deep AI analysis on job match...'),
              ],
            ),
          ] else if (jobController != null &&
              jobController.analysisErrorMessage != null) ...[
            Text(
              jobController.analysisErrorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton.icon(
              onPressed: primaryResumeId != null
                  ? () => jobController.analyzeJob(
                      jobId: job.id,
                      resumeId: primaryResumeId,
                    )
                  : null,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry Analysis'),
            ),
          ] else if (analysis != null) ...[
            Text(
              analysis.summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (analysis.strengths.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Strengths', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final strength in analysis.strengths)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          strength,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (analysis.missingSkills.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Missing Skills',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: analysis.missingSkills
                    .map((skill) => TagChip(label: skill))
                    .toList(),
              ),
            ],
            if (analysis.recommendations.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Recommendations',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              for (final rec in analysis.recommendations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          rec,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ] else ...[
            Text(
              'Get detailed AI insights on how your experience matches this position and what recommendations will boost your fit.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Run AI Match Analysis',
                leading: const Icon(Icons.auto_awesome),
                onPressed: primaryResumeId != null
                    ? () => jobController?.analyzeJob(
                        jobId: job.id,
                        resumeId: primaryResumeId,
                      )
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    children: items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}

class _SkillsBreakdown extends StatelessWidget {
  const _SkillsBreakdown({required this.match});
  final JobMatch match;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (match.matchedSkills.isNotEmpty) ...[
        Text('Matched Skills', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: match.matchedSkills
              .map(
                (skill) => TagChip(label: skill, color: AppColors.successSoft),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (match.missingSkills.isNotEmpty) ...[
        Text('Missing Skills', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: match.missingSkills
              .map((skill) => TagChip(label: skill))
              .toList(),
        ),
      ],
    ],
  );
}
