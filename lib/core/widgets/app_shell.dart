import 'package:flutter/material.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

enum AppNavigationVariant { hunter, optimize }

class AppShell extends StatelessWidget {
  const AppShell({
    required this.child,
    required this.navigationVariant,
    required this.selectedIndex,
    super.key,
    this.title,
    this.showNotificationAction = true,
    this.onNotificationPressed,
  });
  final Widget child;
  final AppNavigationVariant navigationVariant;
  final int selectedIndex;
  final String? title;
  final bool showNotificationAction;
  final VoidCallback? onNotificationPressed;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 72,
      titleSpacing: AppSpacing.md,
      title: title == null ? const _BrandLockup() : Text(title!),
      actions: [
        if (showNotificationAction)
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed:
                onNotificationPressed ??
                () => Navigator.of(context).pushNamed(AppRoutes.alerts),
          ),
        const SizedBox(width: AppSpacing.xs),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
    ),
    body: SafeArea(top: false, child: child),
    bottomNavigationBar: AppBottomNavigation(
      variant: navigationVariant,
      currentIndex: selectedIndex,
    ),
  );
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.variant,
    required this.currentIndex,
    super.key,
  });
  final AppNavigationVariant variant;
  final int currentIndex;
  @override
  Widget build(BuildContext context) {
    final destinations = switch (variant) {
      AppNavigationVariant.hunter => const [
        _NavigationDestination('Home', Icons.home_outlined, AppRoutes.home),
        _NavigationDestination('Jobs', Icons.search_outlined, AppRoutes.jobs),
        _NavigationDestination(
          'Applications',
          Icons.description_outlined,
          AppRoutes.applications,
        ),
        _NavigationDestination(
          'Profile',
          Icons.person_outline,
          AppRoutes.profile,
        ),
      ],
      AppNavigationVariant.optimize => const [
        _NavigationDestination(
          'Optimize',
          Icons.description_outlined,
          AppRoutes.optimizationReady,
        ),
        _NavigationDestination(
          'Jobs',
          Icons.business_center_outlined,
          AppRoutes.jobs,
        ),
        _NavigationDestination(
          'Alerts',
          Icons.notifications_none,
          AppRoutes.alerts,
        ),
        _NavigationDestination(
          'Profile',
          Icons.person_outline,
          AppRoutes.profile,
        ),
      ],
    };
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) =>
          Navigator.of(context).pushReplacementNamed(destinations[index].route),
      destinations: [
        for (final destination in destinations)
          NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.icon),
            label: destination.label,
          ),
      ],
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadii.small,
        ),
        child: const Icon(
          Icons.business_center_outlined,
          size: 20,
          color: Colors.white,
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      Text('AI Job Hunter', style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

class _NavigationDestination {
  const _NavigationDestination(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}
