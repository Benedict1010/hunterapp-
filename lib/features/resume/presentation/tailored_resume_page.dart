import 'package:flutter/material.dart';

import '../../../app/job_scope.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../../jobs/domain/ai_tailoring.dart';

class TailoredResumePage extends StatelessWidget {
  const TailoredResumePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tailoring = JobScope.maybeOf(context)?.currentTailoring;
    return AppShell(
      navigationVariant: AppNavigationVariant.optimize,
      selectedIndex: 0,
      title: 'Tailored Resume',
      showNotificationAction: false,
      child: tailoring == null
          ? const _EmptyTailoringState()
          : _TailoredResumeContent(tailoring: tailoring),
    );
  }
}

class _EmptyTailoringState extends StatelessWidget {
  const _EmptyTailoringState();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined, size: 48),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No tailored resume is available.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Start tailoring from a job detail to create a validated resume version.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _TailoredResumeContent extends StatelessWidget {
  const _TailoredResumeContent({required this.tailoring});

  final AiTailoring tailoring;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'AI Tailored Optimization',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSurface(
            color: AppColors.primarySoft,
            shadows: const [],
            child: Text(
              'This tailored content was returned by the safety-validated AI workflow. Review it before using it in an application.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Tailored Resume', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          AppSurface(
            shadows: const [],
            child: SelectableText(tailoring.tailoredResume),
          ),
          if (tailoring.changesMade.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Recent Changes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final change in tailoring.changesMade)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppSurface(
                  shadows: const [],
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_outlined),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(change)),
                    ],
                  ),
                ),
              ),
          ],
          if (tailoring.warnings.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Review Warnings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final warning in tailoring.warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppSurface(
                  color: AppColors.surfaceSubtle,
                  shadows: const [],
                  child: Text(warning),
                ),
              ),
          ],
        ],
      );
}
