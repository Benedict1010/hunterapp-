import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';
import 'app_chips.dart';
import 'app_surface.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.actionLabel,
    this.onActionPressed,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (actionLabel case final value?)
        TextButton(onPressed: onActionPressed, child: Text(value)),
    ],
  );
}

class InfoCallout extends StatelessWidget {
  const InfoCallout({
    required this.title,
    required this.message,
    super.key,
    this.icon = Icons.auto_awesome_outlined,
  });
  final String title;
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => AppSurface(
    color: AppColors.primarySoft,
    borderColor: AppColors.primary.withValues(alpha: .25),
    shadows: const [],
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
    this.accentColor = AppColors.primary,
    this.trendLabel,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? trendLabel;
  @override
  Widget build(BuildContext context) => AppSurface(
    shadows: const [],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: .12),
                borderRadius: AppRadii.small,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const Spacer(),
            if (trendLabel case final value?) StatusBadge(label: value),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
      ],
    ),
  );
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: AppRadii.small,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          if (leading case final value?) ...[
            value,
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle case final value?)
                  Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          trailing ??
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    ),
  );
}

class MatchScoreCard extends StatelessWidget {
  const MatchScoreCard({
    required this.score,
    super.key,
    this.label = 'AI Match',
    this.message,
  }) : assert(score >= 0 && score <= 100);
  final int score;
  final String label;
  final String? message;
  @override
  Widget build(BuildContext context) => AppSurface(
    color: AppColors.primarySoft,
    borderColor: Colors.transparent,
    shadows: const [],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text('$score%', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(
          value: score / 100,
          minHeight: 6,
          borderRadius: AppRadii.pill,
          backgroundColor: AppColors.border,
          color: AppColors.primary,
        ),
        if (message case final value?) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    ),
  );
}
