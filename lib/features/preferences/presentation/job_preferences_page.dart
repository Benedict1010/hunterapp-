import 'package:flutter/material.dart';

import '../../../app/job_preference_scope.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_chips.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../domain/job_preference.dart';
import 'job_preference_controller.dart';

class JobPreferencesPage extends StatefulWidget {
  const JobPreferencesPage({super.key});
  @override
  State<JobPreferencesPage> createState() => _JobPreferencesPageState();
}

class _JobPreferencesPageState extends State<JobPreferencesPage> {
  late Set<String> _roles;
  late List<String> _locations;
  late String _jobType;
  late String _workMode;
  late double _salary;
  late double _threshold;
  final TextEditingController _locationController = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _roles = {'Product Designer', 'Frontend Engineer'};
    _locations = ['Bangalore, KA', 'Mumbai, MH', 'Remote'];
    _jobType = 'Full-time';
    _workMode = 'Remote';
    _salary = 25000.0;
    _threshold = 85.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = JobPreferenceScope.maybeOf(context);
      if (controller != null &&
          controller.status == JobPreferenceStateStatus.initial) {
        controller.loadPreferences().then((_) {
          if (mounted) _syncFromController(controller);
        });
      } else if (controller != null) {
        _syncFromController(controller);
      }
    });
  }

  void _syncFromController(JobPreferenceController controller) {
    if (_initialized) return;
    final pref = controller.preference;
    setState(() {
      _roles = Set.from(
        pref.preferredRoles.isEmpty
            ? ['Product Designer', 'Frontend Engineer']
            : pref.preferredRoles,
      );
      _locations = List.from(
        pref.preferredLocations.isEmpty
            ? ['Bangalore, KA', 'Mumbai, MH', 'Remote']
            : pref.preferredLocations,
      );
      _jobType = pref.jobType ?? 'Full-time';
      _workMode = pref.workMode ?? 'Remote';
      _salary = (pref.minSalary ?? 25000).toDouble().clamp(10000.0, 50000.0);
      _threshold = (pref.minMatchThreshold ?? 85).toDouble().clamp(50.0, 100.0);
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _addLocation() {
    final text = _locationController.text.trim();
    if (text.isNotEmpty && !_locations.contains(text)) {
      setState(() {
        _locations.add(text);
        _locationController.clear();
      });
    }
  }

  JobPreference _buildCurrentPreference() => JobPreference(
    preferredRoles: _roles.toList(),
    jobType: _jobType,
    workMode: _workMode,
    minSalary: _salary.round(),
    preferredLocations: _locations,
    minMatchThreshold: _threshold.round(),
  );

  @override
  Widget build(BuildContext context) {
    final controller = JobPreferenceScope.maybeOf(context);

    return AppShell(
      navigationVariant: AppNavigationVariant.hunter,
      selectedIndex: 3,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Your Pace',
                    style: Theme.of(
                      context,
                    ).textTheme.displaySmall?.copyWith(fontFamily: 'serif'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tell AI your career non-negotiables. We handle the discovery.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Divider(height: 34),
                  if (controller != null && controller.isLoading) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: AppSpacing.xl),
                  ] else ...[
                    if (controller != null && controller.hasError) ...[
                      AppSurface(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.warning,
                              size: 36,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              controller.errorMessage ??
                                  'Failed to load preferences.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ElevatedButton.icon(
                              onPressed: () => controller.loadPreferences(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    const _PreferenceTitle(
                      icon: Icons.business_center_outlined,
                      title: 'Desired Roles',
                      subtitle: 'Select the titles that match your expertise.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                                'Product Designer',
                                'Frontend Engineer',
                                'Backend Dev',
                                'Fullstack',
                                'Data Scientist',
                                'DevOps',
                                'Mobile Developer',
                              ]
                              .map(
                                (role) => PillChip(
                                  label: role,
                                  selected: _roles.contains(role),
                                  onSelected: (value) => setState(
                                    () => value
                                        ? _roles.add(role)
                                        : _roles.remove(role),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const Divider(height: 42),
                    const _PreferenceTitle(
                      icon: Icons.track_changes_outlined,
                      title: 'Job Type',
                      subtitle: 'What kind of commitment are you looking for?',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _OptionTiles(
                      options: const [
                        ('Full-time', Icons.business_center_outlined),
                        ('Internship', Icons.public_outlined),
                        ('Contract', Icons.apartment_outlined),
                      ],
                      selected: _jobType,
                      onSelected: (value) => setState(() => _jobType = value),
                    ),
                    const Divider(height: 42),
                    const _PreferenceTitle(
                      icon: Icons.laptop_mac_outlined,
                      title: 'Work Mode',
                      subtitle: 'Where do you do your best work?',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _OptionTiles(
                      options: const [
                        ('Remote', Icons.public_outlined),
                        ('Hybrid', Icons.apartment_outlined),
                        ('On-site', Icons.location_on_outlined),
                      ],
                      selected: _workMode,
                      onSelected: (value) => setState(() => _workMode = value),
                    ),
                    const Divider(height: 42),
                    const _PreferenceTitle(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Expected Stipend/Salary',
                      subtitle: 'Adjust your minimum monthly expectations.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _SalaryCard(
                      value: _salary,
                      onChanged: (value) => setState(() => _salary = value),
                    ),
                    const Divider(height: 42),
                    const _PreferenceTitle(
                      icon: Icons.location_on_outlined,
                      title: 'Preferred Locations',
                      subtitle: 'Where should we look for opportunities?',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _locations
                          .map(
                            (location) => InputChip(
                              label: Text(location),
                              onDeleted: () =>
                                  setState(() => _locations.remove(location)),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _locationController,
                      onSubmitted: (_) => _addLocation(),
                      decoration: InputDecoration(
                        hintText: 'Add another city...',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addLocation,
                        ),
                      ),
                    ),
                    const Divider(height: 42),
                    const _PreferenceTitle(
                      icon: Icons.check,
                      title: 'Match Threshold',
                      subtitle:
                          'Only see jobs that align closely with your profile.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ThresholdCard(
                      value: _threshold,
                      onChanged: (value) => setState(() => _threshold = value),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: PrimaryButton(
              label: controller != null && controller.isSaving
                  ? 'Saving...'
                  : 'Save Preferences',
              trailing: const Icon(Icons.arrow_forward_rounded),
              onPressed: controller != null && controller.isSaving
                  ? null
                  : () async {
                      if (controller != null) {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        controller.updateLocalPreference(
                          _buildCurrentPreference(),
                        );
                        final success = await controller.savePreferences();
                        if (success && mounted) {
                          navigator.pushNamed(AppRoutes.home);
                        } else if (mounted && controller.hasError) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                controller.errorMessage ??
                                    'Failed to save preferences.',
                              ),
                            ),
                          );
                        }
                      } else {
                        Navigator.of(context).pushNamed(AppRoutes.home);
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceTitle extends StatelessWidget {
  const _PreferenceTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: const BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: AppRadii.small,
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    ],
  );
}

class _OptionTiles extends StatelessWidget {
  const _OptionTiles({
    required this.options,
    required this.selected,
    required this.onSelected,
  });
  final List<(String, IconData)> options;
  final String selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => Row(
    children: options.map((option) {
      final isSelected = option.$1 == selected;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: option == options.last ? 0 : 10),
          child: InkWell(
            onTap: () => onSelected(option.$1),
            borderRadius: AppRadii.medium,
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: AppRadii.medium,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    option.$2,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    option.$1,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}

class _SalaryCard extends StatelessWidget {
  const _SalaryCard({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => AppSurface(
    color: AppColors.primarySoft,
    borderColor: Colors.transparent,
    shadows: const [],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'MONTHLY (MIN)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                letterSpacing: .5,
              ),
            ),
            const Spacer(),
            Text(
              'RANGE CAP',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              '₹${value.round().toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontFamily: 'serif',
              ),
            ),
            const Spacer(),
            Text('₹50,000+', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        Slider(
          value: value,
          min: 10000,
          max: 50000,
          divisions: 8,
          onChanged: onChanged,
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('₹10K'), Text('₹50K')],
        ),
      ],
    ),
  );
}

class _ThresholdCard extends StatelessWidget {
  const _ThresholdCard({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppSurface(
        color: AppColors.navy,
        borderColor: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI CONFIDENCE',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white70,
                      letterSpacing: .5,
                    ),
                  ),
                  Text(
                    '${value.round()}% Minimum Match',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.track_changes, color: Colors.white),
            ),
          ],
        ),
      ),
      Slider(
        value: value,
        min: 50,
        max: 100,
        divisions: 10,
        onChanged: onChanged,
      ),
    ],
  );
}
