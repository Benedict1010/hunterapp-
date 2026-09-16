import 'package:flutter/material.dart';

import '../../core/widgets/app_shell.dart';
import '../../features/job_sources/presentation/job_sources_page.dart';
import '../../features/onboarding/presentation/landing_page.dart';
import '../../features/preferences/presentation/job_preferences_page.dart';
import '../../features/placeholder/presentation/foundation_placeholder_page.dart';
import '../../features/resume/presentation/resume_verified_page.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    final screen = switch (settings.name) {
      AppRoutes.landing => const LandingPage(),
      AppRoutes.resumeVerified => const ResumeVerifiedPage(),
      AppRoutes.jobSources => const JobSourcesPage(),
      AppRoutes.preferences => const JobPreferencesPage(),
      _ => null,
    };
    if (screen != null) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => screen,
      );
    }
    final configuration = _routes[settings.name] ?? _unknownRoute;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => FoundationPlaceholderPage(configuration: configuration),
    );
  }

  static const _unknownRoute = PlaceholderPageConfiguration(
    title: 'Route unavailable',
    navigationVariant: null,
  );
  static const Map<String, PlaceholderPageConfiguration> _routes = {
    AppRoutes.home: PlaceholderPageConfiguration(
      title: 'Home',
      navigationVariant: AppNavigationVariant.hunter,
    ),
    AppRoutes.jobs: PlaceholderPageConfiguration(
      title: 'Jobs For You',
      navigationVariant: AppNavigationVariant.hunter,
      selectedIndex: 1,
    ),
    AppRoutes.jobDetail: PlaceholderPageConfiguration(
      title: 'Job Detail',
      navigationVariant: AppNavigationVariant.hunter,
      selectedIndex: 1,
    ),
    AppRoutes.optimizationReady: PlaceholderPageConfiguration(
      title: 'Resume Optimization Ready',
      navigationVariant: AppNavigationVariant.optimize,
    ),
    AppRoutes.tailoredResume: PlaceholderPageConfiguration(
      title: 'Tailored Resume',
      navigationVariant: AppNavigationVariant.optimize,
    ),
    AppRoutes.applications: PlaceholderPageConfiguration(
      title: 'Applications',
      navigationVariant: AppNavigationVariant.hunter,
      selectedIndex: 2,
    ),
    AppRoutes.applicationDetail: PlaceholderPageConfiguration(
      title: 'Application Details',
      navigationVariant: AppNavigationVariant.optimize,
      selectedIndex: 1,
    ),
    AppRoutes.alerts: PlaceholderPageConfiguration(
      title: 'Notifications',
      navigationVariant: AppNavigationVariant.optimize,
      selectedIndex: 2,
    ),
    AppRoutes.profile: PlaceholderPageConfiguration(
      title: 'Account Profile',
      navigationVariant: AppNavigationVariant.optimize,
      selectedIndex: 3,
    ),
    AppRoutes.settings: PlaceholderPageConfiguration(
      title: 'Settings',
      navigationVariant: AppNavigationVariant.optimize,
      selectedIndex: 3,
    ),
  };
}
