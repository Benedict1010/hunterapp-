import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/application_scope.dart';
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
import '../../applications/domain/job_application.dart';
import '../../applications/presentation/application_controller.dart';
import '../../resume/domain/resume_version.dart';
import '../../resume/presentation/resume_controller.dart';
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
  var _isPreparingTailoring = false;
  String? _tailoredResumeVersionId;

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
    final applicationController = ApplicationScope.maybeOf(context);
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
                      onPressed:
                          jobController?.isTailoring == true ||
                              _isPreparingTailoring
                          ? null
                          : () => _tailorResume(
                              context,
                              job,
                              primaryResume?.id,
                              jobController,
                              resumeController,
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Apply Now',
                      onPressed: () => _showApplyModal(
                        context,
                        job,
                        resumeController,
                        applicationController,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _tailorResume(
    BuildContext context,
    Job job,
    String? resumeId,
    JobController? jobController,
    ResumeController? resumeController,
  ) async {
    if (_isPreparingTailoring) return;
    setState(() => _isPreparingTailoring = true);
    _tailoredResumeVersionId = null;
    try {
      if (resumeId == null || jobController == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload a primary resume before tailoring.'),
          ),
        );
        return;
      }
      if (resumeController == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to verify the tailored resume version.'),
          ),
        );
        return;
      }

      final existingVersions = await resumeController.loadVersions(resumeId);
      if (!context.mounted) return;
      if (resumeController.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resumeController.errorMessage ??
                  'Unable to verify the tailored resume version.',
            ),
          ),
        );
        return;
      }

      final tailoring = await jobController.tailorResume(
        jobId: job.id,
        resumeId: resumeId,
      );
      if (!context.mounted) return;
      if (tailoring == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              jobController.tailoringErrorMessage ?? 'Failed to tailor resume.',
            ),
          ),
        );
        return;
      }

      final versions = await resumeController.loadVersions(resumeId);
      if (!context.mounted) return;
      if (resumeController.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resumeController.errorMessage ??
                  'Unable to verify the tailored resume version.',
            ),
          ),
        );
        return;
      }
      final persistedVersion = findNewTailoredResumeVersion(
        existingVersions: existingVersions,
        refreshedVersions: versions,
        jobId: job.id,
        contentText: tailoring.tailoredResume,
      );
      if (persistedVersion == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tailored resume could not be verified. Please try again.',
            ),
          ),
        );
        return;
      }

      _tailoredResumeVersionId = persistedVersion.id;
      Navigator.of(context).pushNamed(AppRoutes.tailoredResume);
    } finally {
      if (mounted) {
        setState(() => _isPreparingTailoring = false);
      }
    }
  }

  void _showApplyModal(
    BuildContext context,
    Job job,
    ResumeController? resumeController,
    ApplicationController? applicationController,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apply to ${job.title}',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Company: ${job.company}',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              if (job.externalUrl.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final uri = Uri.tryParse(job.externalUrl.trim());
                    if (uri != null &&
                        (uri.scheme == 'http' || uri.scheme == 'https')) {
                      try {
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      } catch (_) {}
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invalid URL: ${job.externalUrl}'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open External Application URL'),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              PrimaryButton(
                label: 'Confirm & Track Application',
                leading: const Icon(Icons.check_circle_outline),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _trackApplication(
                    context,
                    job,
                    resumeController,
                    applicationController,
                    _tailoredResumeVersionId,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _trackApplication(
    BuildContext context,
    Job job,
    ResumeController? resumeController,
    ApplicationController? applicationController,
    String? tailoredResumeVersionId,
  ) async {
    if (applicationController == null) return;

    final primaryResume = resumeController?.primaryResume;
    if (primaryResume == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload or select a primary resume before tracking an application.',
          ),
        ),
      );
      return;
    }

    final versions =
        await resumeController?.loadVersions(primaryResume.id) ?? [];
    if (!context.mounted) return;
    if (versions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No resume version found for primary resume.'),
        ),
      );
      return;
    }

    final intendedTailoredVersion = tailoredResumeVersionId == null
        ? null
        : versions
              .where(
                (version) =>
                    version.id == tailoredResumeVersionId &&
                    version.versionType == 'tailored' &&
                    version.jobId == job.id,
              )
              .firstOrNull;
    if (tailoredResumeVersionId != null && intendedTailoredVersion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The tailored resume version is no longer available. Please tailor again.',
          ),
        ),
      );
      return;
    }

    final resumeVersion =
        intendedTailoredVersion ??
        versions.firstWhere(
          (version) => version.versionType == 'original',
          orElse: () => versions.first,
        );

    final app = await applicationController.createApplication(
      jobId: job.id,
      resumeVersionId: resumeVersion.id,
      applicationUrl: job.externalUrl.isNotEmpty ? job.externalUrl : null,
      source: job.source.isNotEmpty ? job.source : null,
      status: ApplicationStatus.applied,
    );

    if (context.mounted) {
      if (app != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application tracked successfully!')),
        );
      } else if (applicationController.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(applicationController.errorMessage!)),
        );
      }
    }
  }

  Widget _buildMatchSection({
    required BuildContext context,
    required JobController? jobController,
    required Job job,
    required String? primaryResumeId,
    required JobMatch? match,
  }) {
    if (primaryResumeId == null) {
      return AppSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Primary Resume Required',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Upload or select a primary resume to calculate your personalized match score.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.resumeVerified),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Manage Resumes'),
            ),
          ],
        ),
      );
    }

    if (match != null && match.resumeId == primaryResumeId) {
      return MatchScoreCard(
        score: match.score,
        label: 'AI Skill Analysis',
        message: match.explanation != null && match.explanation!.isNotEmpty
            ? '“${match.explanation}”'
            : 'Match calculated based on your primary resume and job requirements.',
      );
    }

    if (jobController != null && jobController.isCalculatingMatch) {
      return const AppSurface(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppSpacing.sm),
            Text('Calculating personalized match...'),
          ],
        ),
      );
    }

    if (jobController != null && jobController.matchErrorMessage != null) {
      return AppSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              jobController.matchErrorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton.icon(
              onPressed: () => jobController.calculateMatch(
                jobId: job.id,
                resumeId: primaryResumeId,
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry Match Calculation'),
            ),
          ],
        ),
      );
    }

    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Match Score Yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Calculate match score against your primary resume.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => jobController?.calculateMatch(
              jobId: job.id,
              resumeId: primaryResumeId,
            ),
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Calculate'),
          ),
        ],
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
