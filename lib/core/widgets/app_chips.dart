import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

class PillChip extends StatelessWidget {
  const PillChip({
    required this.label,
    super.key,
    this.selected = false,
    this.onSelected,
    this.icon,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? icon;
  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    avatar: icon,
    showCheckmark: false,
  );
}

class TagChip extends StatelessWidget {
  const TagChip({
    required this.label,
    super.key,
    this.color = AppColors.surfaceSubtle,
  });
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.xxs,
    ),
    decoration: BoxDecoration(color: color, borderRadius: AppRadii.pill),
    child: Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: .4,
      ),
    ),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    super.key,
    this.color = AppColors.success,
    this.icon = Icons.check_circle_outline,
  });
  final String label;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xxs,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: AppRadii.pill,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    ),
  );
}
