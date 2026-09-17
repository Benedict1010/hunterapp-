import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_chips.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../data/mock_applications.dart';
import '../domain/job_application.dart';

class ApplicationDetailsPage extends StatelessWidget {
  const ApplicationDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final detail = applicationDetail;
    return AppShell(
      navigationVariant: AppNavigationVariant.optimize,
      selectedIndex: 1,
      showNotificationAction: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
              const TagChip(
                label: 'Application Details',
                color: AppColors.primarySoft,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProcessBanner(),
          const SizedBox(height: 16),
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: AppRadii.small,
                      ),
                      child: const Icon(
                        Icons.code_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.application.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            detail.application.company,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _message(
                        context,
                        'Application options are not available in this local preview.',
                      ),
                      icon: const Icon(Icons.more_horiz),
                      tooltip: 'More options',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TagChip(label: detail.employmentType),
                    TagChip(label: detail.application.location),
                    TagChip(label: 'Applied ${detail.application.date}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'HIRING PROCESS',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < detail.timeline.length; index++)
            _TimelineStep(
              stage: detail.timeline[index],
              isLast: index == detail.timeline.length - 1,
            ),
          const SizedBox(height: 12),
          AppSurface(
            color: AppColors.primarySoft,
            borderColor: Colors.transparent,
            shadows: const [],
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.open_in_new_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'External Tracking',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Text(
                        'View this application on the employer portal.',
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _message(
                    context,
                    'External portal tracking is not available in this local preview.',
                  ),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            detail.updatedAt,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ProcessBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppSurface(
    color: AppColors.surfaceSubtle,
    shadows: const [],
    child: Row(
      children: [
        const Icon(
          Icons.account_tree_outlined,
          color: AppColors.primary,
          size: 42,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are in the interview stage',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const LinearProgressIndicator(
                value: .72,
                minHeight: 7,
                borderRadius: AppRadii.pill,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.stage, required this.isLast});
  final ApplicationTimelineStage stage;
  final bool isLast;
  @override
  Widget build(BuildContext context) {
    final color = switch (stage.status) {
      ApplicationStageStatus.completed => AppColors.success,
      ApplicationStageStatus.current => AppColors.primary,
      ApplicationStageStatus.upcoming => AppColors.border,
    };
    final icon = switch (stage.status) {
      ApplicationStageStatus.completed => Icons.check,
      ApplicationStageStatus.current => Icons.calendar_today_outlined,
      ApplicationStageStatus.upcoming => Icons.circle_outlined,
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: color.withValues(alpha: .16),
                  child: Icon(icon, size: 16, color: color),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: stage.status == ApplicationStageStatus.upcoming
                          ? AppColors.textSecondary
                          : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stage.date,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _message(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));
