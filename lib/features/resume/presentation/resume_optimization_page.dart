import 'package:flutter/material.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_chips.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../domain/resume_optimization.dart';

class ResumeOptimizationPage extends StatelessWidget {
  const ResumeOptimizationPage({super.key});
  @override
  Widget build(BuildContext context) => AppShell(
    navigationVariant: AppNavigationVariant.optimize,
    selectedIndex: 0,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Text(
          'RESUME OPTIMIZATION',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.primary,
            letterSpacing: .7,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Optimization Ready',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSurface(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OptimizationArtwork(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tailored for',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            resumeOptimization.role,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const TagChip(label: 'Optimized'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _ScoreComparison(),
                    const SizedBox(height: AppSpacing.md),
                    const _ImprovementNotice(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Text('Source File', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            TextButton(
              onPressed: () => _notice(
                context,
                'Changing source files will be available later.',
              ),
              child: const Text('Change'),
            ),
          ],
        ),
        AppSurface(
          shadows: const [],
          child: Row(
            children: [
              const Icon(Icons.description_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resumeOptimization.sourceFile,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text('PDF • 2.4 MB • Updated today'),
                  ],
                ),
              ),
              const Icon(Icons.visibility_outlined),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const Icon(Icons.bolt_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Key Improvements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final improvement in resumeOptimization.improvements)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ImprovementCard(improvement: improvement),
          ),
        PrimaryButton(
          label: 'Review Tailored Resume',
          trailing: const Icon(Icons.arrow_forward),
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.tailoredResume),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: SecondaryOutlinedButton(
                label: 'Download PDF',
                leading: const Icon(Icons.download_outlined),
                onPressed: () =>
                    _notice(context, 'PDF download will be available later.'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SecondaryOutlinedButton(
                label: 'Apply Now',
                leading: const Icon(Icons.adjust_outlined),
                onPressed: () => _notice(
                  context,
                  'External application integration will be implemented later.',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const AppSurface(
          color: AppColors.surfaceSubtle,
          shadows: [],
          child: Text(
            '“Your resume is now focused on cloud architecture and front-end optimization as requested by the hiring team.”',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

void _notice(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

class _OptimizationArtwork extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 250,
    decoration: const BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    child: const Center(
      child: Icon(
        Icons.document_scanner_outlined,
        size: 110,
        color: AppColors.primary,
      ),
    ),
  );
}

class _ScoreComparison extends StatelessWidget {
  const _ScoreComparison();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _Score(
          label: 'PREVIOUS',
          score: resumeOptimization.previousScore,
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: _Score(
          label: 'NEW SCORE',
          score: resumeOptimization.newScore,
          highlighted: true,
        ),
      ),
    ],
  );
}

class _Score extends StatelessWidget {
  const _Score({
    required this.label,
    required this.score,
    this.highlighted = false,
  });
  final String label;
  final int score;
  final bool highlighted;
  @override
  Widget build(BuildContext context) => AppSurface(
    color: highlighted ? AppColors.primarySoft : AppColors.surfaceSubtle,
    shadows: const [],
    borderColor: highlighted
        ? AppColors.primary.withValues(alpha: .25)
        : AppColors.border,
    child: Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: highlighted ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        Text(
          '$score%',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: highlighted ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _ImprovementNotice extends StatelessWidget {
  const _ImprovementNotice();
  @override
  Widget build(BuildContext context) => const AppSurface(
    shadows: [],
    child: Row(
      children: [
        Icon(Icons.verified_user_outlined),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Your match score increased by 16%.\nThis resume is now highly competitive for this role.',
          ),
        ),
      ],
    ),
  );
}

class _ImprovementCard extends StatelessWidget {
  const _ImprovementCard({required this.improvement});
  final ResumeImprovement improvement;
  @override
  Widget build(BuildContext context) => AppSurface(
    shadows: const [],
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      improvement.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TagChip(label: improvement.impact),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                improvement.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
