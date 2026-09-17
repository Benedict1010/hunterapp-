import 'package:flutter/material.dart';

import '../../features/applications/presentation/applications_page.dart';
import '../../features/applications/presentation/application_details_page.dart';
import '../../features/job_sources/presentation/job_sources_page.dart';
import '../../features/jobs/presentation/job_detail_page.dart';
import '../../features/jobs/presentation/jobs_for_you_page.dart';
import '../../features/home/presentation/home_dashboard_page.dart';
import '../../features/onboarding/presentation/landing_page.dart';
import '../../features/preferences/presentation/job_preferences_page.dart';
import '../../features/placeholder/presentation/foundation_placeholder_page.dart';
import '../../features/resume/presentation/resume_verified_page.dart';
import '../../features/resume/presentation/resume_optimization_page.dart';
import '../../features/resume/presentation/tailored_resume_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) {
    final screen = switch (settings.name) {
      AppRoutes.landing => const LandingPage(),
      AppRoutes.resumeVerified => const ResumeVerifiedPage(),
      AppRoutes.jobSources => const JobSourcesPage(),
      AppRoutes.preferences => const JobPreferencesPage(),
      AppRoutes.home => const HomeDashboardPage(),
      AppRoutes.jobs => const JobsForYouPage(),
      AppRoutes.jobDetail => const JobDetailPage(),
      AppRoutes.optimizationReady => const ResumeOptimizationPage(),
      AppRoutes.tailoredResume => const TailoredResumePage(),
      AppRoutes.applications => const ApplicationsPage(),
      AppRoutes.applicationDetails => const ApplicationDetailsPage(),
      '/application-detail' => const ApplicationDetailsPage(),
      AppRoutes.notifications => const NotificationsPage(),
      '/alerts' => const NotificationsPage(),
      AppRoutes.profile => const ProfilePage(),
      AppRoutes.settings => const SettingsPage(),
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
  static const Map<String, PlaceholderPageConfiguration> _routes = {};
}
