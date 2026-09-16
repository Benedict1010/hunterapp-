import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';

class PlaceholderPageConfiguration {
  const PlaceholderPageConfiguration({
    required this.title,
    required this.navigationVariant,
    this.selectedIndex = 0,
  });
  final String title;
  final AppNavigationVariant? navigationVariant;
  final int selectedIndex;
}

/// Temporary route target only. Product screen UI is deliberately deferred.
class FoundationPlaceholderPage extends StatelessWidget {
  const FoundationPlaceholderPage({required this.configuration, super.key});
  final PlaceholderPageConfiguration configuration;
  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: AppConstants.pagePadding,
      child: Center(
        child: AppSurface(
          shadows: const [],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_outlined,
                color: AppColors.primary,
                size: 36,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                configuration.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Screen UI is intentionally deferred. This route verifies the shared foundation.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
    final variant = configuration.navigationVariant;
    if (variant == null) {
      return Scaffold(
        appBar: AppBar(title: Text(configuration.title)),
        body: SafeArea(child: content),
      );
    }
    return AppShell(
      title: configuration.title,
      navigationVariant: variant,
      selectedIndex: configuration.selectedIndex,
      child: content,
    );
  }
}
