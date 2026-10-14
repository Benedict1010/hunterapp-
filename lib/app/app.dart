import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../features/applications/data/application_service.dart';
import '../features/applications/presentation/application_controller.dart';
import '../features/auth/data/auth_service.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/jobs/data/job_service.dart';
import '../features/jobs/presentation/job_controller.dart';
import '../features/notifications/data/notification_service.dart';
import '../features/notifications/presentation/notification_controller.dart';
import '../features/resume/data/resume_service.dart';
import '../features/resume/presentation/resume_controller.dart';
import 'application_scope.dart';
import 'auth_scope.dart';
import 'job_scope.dart';
import 'notification_scope.dart';
import 'resume_scope.dart';
import 'router/app_router.dart';
import 'router/app_routes.dart';
import 'theme/app_theme.dart';

class AiJobHunterApp extends StatefulWidget {
  final AuthController? authController;
  final ResumeController? resumeController;
  final JobController? jobController;
  final ApplicationController? applicationController;
  final NotificationController? notificationController;

  const AiJobHunterApp({
    super.key,
    this.authController,
    this.resumeController,
    this.jobController,
    this.applicationController,
    this.notificationController,
  });

  @override
  State<AiJobHunterApp> createState() => _AiJobHunterAppState();
}

class _AiJobHunterAppState extends State<AiJobHunterApp> {
  late final AuthController _authController;
  late final ResumeController _resumeController;
  late final JobController _jobController;
  late final ApplicationController _applicationController;
  late final NotificationController _notificationController;

  @override
  void initState() {
    super.initState();
    final tokenStorage = FileTokenStorage();
    final apiClient = ApiClient(
      apiConfig: const ApiConfig(),
      tokenStorage: tokenStorage,
    );

    if (widget.authController != null) {
      _authController = widget.authController!;
    } else {
      final authService = AuthService(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );
      _authController = AuthController(authService: authService);
    }

    if (widget.resumeController != null) {
      _resumeController = widget.resumeController!;
    } else {
      final resumeService = ResumeService(apiClient: apiClient);
      _resumeController = ResumeController(resumeService: resumeService);
    }

    if (widget.jobController != null) {
      _jobController = widget.jobController!;
    } else {
      final jobService = JobService(apiClient: apiClient);
      _jobController = JobController(jobService: jobService);
    }

    if (widget.applicationController != null) {
      _applicationController = widget.applicationController!;
    } else {
      final applicationService = ApplicationService(apiClient: apiClient);
      _applicationController = ApplicationController(
        applicationService: applicationService,
      );
    }

    if (widget.notificationController != null) {
      _notificationController = widget.notificationController!;
    } else {
      final notificationService = NotificationService(apiClient: apiClient);
      _notificationController = NotificationController(
        notificationService: notificationService,
      );
    }

    _authController.checkSession();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _authController,
      child: ResumeScope(
        controller: _resumeController,
        child: JobScope(
          controller: _jobController,
          child: ApplicationScope(
            controller: _applicationController,
            child: NotificationScope(
              controller: _notificationController,
              child: MaterialApp(
                title: 'AI Job Hunter',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                initialRoute: AppRoutes.landing,
                onGenerateRoute: AppRouter.onGenerateRoute,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
