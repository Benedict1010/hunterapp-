import 'package:flutter/material.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/content_widgets.dart';
import '../data/mock_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var _provider = 'Lumina GPT-4o';
  var _pushNotifications = true;
  var _autoOptimization = false;
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
            Expanded(
              child: Text(
                'Account Profile',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            IconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.settings),
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Stack(
            children: [
              const CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primarySoft,
                child: Icon(Icons.person, size: 55, color: AppColors.primary),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    onPressed: () => _message(
                      'Profile photo editing is not available in this local preview.',
                    ),
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 17,
                    ),
                    tooltip: 'Edit profile photo',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          mockProfile.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          mockProfile.email,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        const Center(child: _RoleBadge()),
        const SizedBox(height: 22),
        Row(
          children: [
            for (final stat in mockProfile.stats)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AppSurface(
                    shadows: const [],
                    child: Column(
                      children: [
                        Text(
                          stat.value,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          stat.label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          'AI PROVIDER',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        _ProviderCard(
          name: 'Lumina GPT-4o',
          detail: 'Best for Resumes',
          selected: _provider == 'Lumina GPT-4o',
          premium: true,
          onTap: () => setState(() => _provider = 'Lumina GPT-4o'),
        ),
        const SizedBox(height: 10),
        _ProviderCard(
          name: 'Claude 3.5 Sonnet',
          detail: 'Thoughtful career guidance',
          selected: _provider == 'Claude 3.5 Sonnet',
          onTap: () => setState(() => _provider = 'Claude 3.5 Sonnet'),
        ),
        const SizedBox(height: 24),
        Text(
          'MANAGE ACCOUNT',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
        ),
        AppSurface(
          shadows: const [],
          child: Column(
            children: [
              SettingsRow(
                title: 'Personal Information',
                leading: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                ),
                onTap: () => _message(
                  'Personal information editing is not available in this local preview.',
                ),
              ),
              const Divider(),
              SettingsRow(
                title: 'Job Preferences',
                leading: const Icon(Icons.tune, color: AppColors.primary),
                onTap: () => Navigator.of(context).pushNamed('/preferences'),
              ),
              const Divider(),
              SettingsRow(
                title: 'App Language',
                subtitle: 'English',
                leading: const Icon(Icons.language, color: AppColors.primary),
                onTap: () => _message(
                  'Language selection is not available in this local preview.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'PREFERENCES',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
        ),
        AppSurface(
          shadows: const [],
          child: Column(
            children: [
              SettingsRow(
                title: 'Push Notifications',
                leading: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                ),
                trailing: Switch(
                  value: _pushNotifications,
                  onChanged: (value) =>
                      setState(() => _pushNotifications = value),
                ),
              ),
              const Divider(),
              SettingsRow(
                title: 'Auto-Optimization',
                leading: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.primary,
                ),
                trailing: Switch(
                  value: _autoOptimization,
                  onChanged: (value) =>
                      setState(() => _autoOptimization = value),
                ),
              ),
              const Divider(),
              SettingsRow(
                title: 'Security & Privacy',
                leading: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                ),
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.settings),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TextButton.icon(
          onPressed: () => _message(
            'Sign out is not available because this app uses local mock data.',
          ),
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text(
            'Sign Out',
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
  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: const BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: AppRadii.pill,
    ),
    child: Text(
      'DEVELOPER',
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
    ),
  );
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.name,
    required this.detail,
    required this.selected,
    required this.onTap,
    this.premium = false,
  });
  final String name, detail;
  final bool selected, premium;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: AppRadii.medium,
    child: AppSurface(
      borderColor: selected ? AppColors.primary : AppColors.border,
      color: selected ? AppColors.primarySoft : AppColors.surface,
      shadows: const [],
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(detail, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (premium)
            const Text(
              'PREMIUM ACTIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    ),
  );
}
