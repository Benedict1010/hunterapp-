import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'router/app_routes.dart';
import 'theme/app_theme.dart';

class AiJobHunterApp extends StatelessWidget {
  const AiJobHunterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Job Hunter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.landing,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
