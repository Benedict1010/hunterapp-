import 'package:flutter/material.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_chips.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/content_widgets.dart';
import '../data/mock_home_data.dart';

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    navigationVariant: AppNavigationVariant.hunter,
    selectedIndex: 0,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good morning,',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontFamily: 'serif'),
          ),
          Text(
            'Benedict',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.primary,
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Here's what's happening with your job search.",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _ActiveSearchCard(),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Search Insights'),
          const SizedBox(height: AppSpacing.sm),
          const _MetricsGrid(),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Your top match',
            actionLabel: 'View All',
            onActionPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.jobs),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TopMatchCard(
            onReview: () =>
                Navigator.of(context).pushNamed(AppRoutes.jobDetail),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _ProfilePrompt(),
        ],
      ),
    ),
  );
}

class _ActiveSearchCard extends StatelessWidget {
  const _ActiveSearchCard();

  @override
  Widget build(BuildContext context) => AppSurface(
    color: AppColors.primarySoft,
    borderColor: Colors.transparent,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    'AI JOB SEARCH ACTIVE',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      letterSpacing: .7,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Intelligent Hunting...',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Searching LinkedIn, Unstop, and Internshala for roles matching your resume.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Manage Search'),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.psychology_outlined,
            color: AppColors.primary,
            size: 36,
          ),
        ),
      ],
    ),
  );
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid();
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    childAspectRatio: 1.55,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: AppSpacing.sm,
    crossAxisSpacing: AppSpacing.sm,
    children: homeMetrics
        .map(
          (metric) => MetricTile(
            label: metric.label,
            value: metric.value,
            icon: metric.icon,
            accentColor: metric.accentColor,
            trendLabel: metric.trendLabel,
          ),
        )
        .toList(),
  );
}

class _TopMatchCard extends StatelessWidget {
  const _TopMatchCard({required this.onReview});
  final VoidCallback onReview;
  @override
  Widget build(BuildContext context) => AppSurface(
    color: AppColors.navy,
    borderColor: Colors.transparent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const TagChip(label: 'Top Match Ready', color: Color(0xFF27477D)),
            const Spacer(),
            const Icon(Icons.more_horiz, color: Colors.white70),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Senior Product Designer',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 3),
        const Text('Google Cloud', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Based on your resume and preferences, you have a 98% skill match for this role.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(
          onPressed: onReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
          ),
          child: const SizedBox(
            width: double.infinity,
            child: Center(child: Text('Review & Apply Now')),
          ),
        ),
      ],
    ),
  );
}

class _ProfilePrompt extends StatelessWidget {
  const _ProfilePrompt();
  @override
  Widget build(BuildContext context) => AppSurface(
    shadows: const [],
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: AppColors.surfaceSubtle,
          child: Icon(
            Icons.track_changes_outlined,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete your profile',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(
                'Add portfolio links to increase match accuracy by 25%.',
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward),
      ],
    ),
  );
}
