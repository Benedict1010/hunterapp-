import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../features/auth/data/auth_service.dart';
import '../features/auth/presentation/auth_controller.dart';
import 'auth_scope.dart';
import 'router/app_router.dart';
import 'router/app_routes.dart';
import 'theme/app_theme.dart';

class AiJobHunterApp extends StatefulWidget {
  final AuthController? authController;

  const AiJobHunterApp({super.key, this.authController});

  @override
  State<AiJobHunterApp> createState() => _AiJobHunterAppState();
}

class _AiJobHunterAppState extends State<AiJobHunterApp> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    if (widget.authController != null) {
      _authController = widget.authController!;
    } else {
      final tokenStorage = FileTokenStorage();
      final apiClient = ApiClient(
        apiConfig: const ApiConfig(),
        tokenStorage: tokenStorage,
      );
      final authService = AuthService(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
      );
      _authController = AuthController(authService: authService);
    }
    _authController.checkSession();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _authController,
      child: MaterialApp(
        title: 'AI Job Hunter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: AppRoutes.landing,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
