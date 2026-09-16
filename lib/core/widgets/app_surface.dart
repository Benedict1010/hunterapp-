import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

class AppSurface extends StatelessWidget {
  const AppSurface({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
    this.borderRadius = AppRadii.medium,
    this.shadows = AppShadows.card,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: borderColor),
      borderRadius: borderRadius,
      boxShadow: shadows,
    ),
    child: Padding(padding: padding, child: child),
  );
}
