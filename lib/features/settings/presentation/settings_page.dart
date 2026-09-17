import 'package:flutter/material.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/content_widgets.dart';
import '../data/mock_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _smartTailoring,
      _suggestions,
      _alerts,
      _remoteOnly,
      _publicProfile,
      _shareData;
  @override
  void initState() {
    super.initState();
    _smartTailoring = mockSettings.smartTailoring;
    _suggestions = mockSettings.realTimeSuggestions;
    _alerts = mockSettings.smartAlerts;
    _remoteOnly = mockSettings.remoteOnly;
    _publicProfile = mockSettings.publicProfile;
    _shareData = mockSettings.shareUsageData;
  }

  @override
  Widget build(BuildContext context) => AppShell(
    navigationVariant: AppNavigationVariant.optimize,
    selectedIndex: 3,
    showNotificationAction: false,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      children: [
        Row(
          children: [
            Text('Settings', style: Theme.of(context).textTheme.displaySmall),
            const Spacer(),
            IconButton(
              onPressed: () => _message(
                'Settings are stored locally while the app is open.',
              ),
              icon: const Icon(Icons.info_outline),
              tooltip: 'About settings',
            ),
          ],
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () =>
              Navigator.of(context).pushReplacementNamed(AppRoutes.profile),
          child: AppSurface(
            shadows: const [],
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alex Rivera',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Text('Developer · alex.rivera@email.com'),
                    ],
                  ),
                ),
                const Text(
                  'Edit',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        _Section(
          title: 'AI CAREER INTELLIGENCE',
          child: Column(
            children: [
              _toggle(
                'Smart AI Tailoring',
                'Personalize resume improvements',
                Icons.auto_awesome_outlined,
                _smartTailoring,
                (value) => setState(() => _smartTailoring = value),
              ),
              const Divider(),
              _toggle(
                'Real-time Suggestions',
                'Show guidance while you browse',
                Icons.lightbulb_outline,
                _suggestions,
                (value) => setState(() => _suggestions = value),
              ),
              const Divider(),
              SettingsRow(
                title: 'Target Role Preferences',
                subtitle: 'SOFTWARE ENGINEER',
                leading: const Icon(
                  Icons.work_outline,
                  color: AppColors.primary,
                ),
                onTap: () => Navigator.of(context).pushNamed('/preferences'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _Section(
          title: 'JOB SEARCH & ALERTS',
          child: Column(
            children: [
              _toggle(
                'Smart Job Alerts',
                'Receive relevant opportunities',
                Icons.notifications_outlined,
                _alerts,
                (value) => setState(() => _alerts = value),
              ),
              const Divider(),
              SettingsRow(
                title: 'Remote Work Only',
                subtitle: _remoteOnly ? 'ENABLED' : 'DISABLED',
                leading: const Icon(
                  Icons.home_work_outlined,
                  color: AppColors.primary,
                ),
                trailing: Switch(
                  value: _remoteOnly,
                  onChanged: (value) => setState(() => _remoteOnly = value),
                ),
              ),
              const Divider(),
              SettingsRow(
                title: 'Preferred Salary Range',
                subtitle: '\$120K+',
                leading: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.primary,
                ),
                onTap: () => _message(
                  'Salary preferences are not editable in this local preview.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        AppSurface(
          color: AppColors.primarySoft,
          borderColor: Colors.transparent,
          shadows: const [],
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppColors.primary,
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your data, protected',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text(
                      'Your career preferences and application data remain under your control.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _Section(
          title: 'PRIVACY CONTROLS',
          child: Column(
            children: [
              _toggle(
                'Public Profile',
                'Allow employers to discover you',
                Icons.public_outlined,
                _publicProfile,
                (value) => setState(() => _publicProfile = value),
              ),
              const Divider(),
              _toggle(
                'Share Usage Data',
                'Help improve AI Job Hunter',
                Icons.data_usage_outlined,
                _shareData,
                (value) => setState(() => _shareData = value),
              ),
              const Divider(),
              SettingsRow(
                title: 'Communication Preferences',
                leading: const Icon(
                  Icons.mail_outline,
                  color: AppColors.primary,
                ),
                onTap: () => _message(
                  'Communication preferences are not available in this local preview.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _Section(
          title: 'SUPPORT',
          child: SettingsRow(
            title: 'Help & Support',
            leading: const Icon(Icons.help_outline, color: AppColors.primary),
            onTap: () => _message(
              'Help and support are not available in this local preview.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _message(
            'Log out is not available because this app uses local mock data.',
          ),
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text(
            'Log Out',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'AI Job Hunter v1.0.0',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
  Widget _toggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) => SettingsRow(
    title: title,
    subtitle: subtitle,
    leading: Icon(icon, color: AppColors.primary),
    trailing: Switch(value: value, onChanged: onChanged),
  );
  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
      ),
      const SizedBox(height: 10),
      AppSurface(shadows: const [], child: child),
    ],
  );
}
