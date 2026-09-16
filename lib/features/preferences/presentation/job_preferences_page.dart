import 'package:flutter/material.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_chips.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';

class JobPreferencesPage extends StatefulWidget {
  const JobPreferencesPage({super.key});
  @override
  State<JobPreferencesPage> createState() => _JobPreferencesPageState();
}

class _JobPreferencesPageState extends State<JobPreferencesPage> {
  final roles = <String>{'Product Designer', 'Frontend Engineer'};
  final locations = <String>['Bangalore, KA', 'Mumbai, MH', 'Remote'];
  var jobType = 'Full-time';
  var workMode = 'Remote';
  var salary = 25000.0;
  var threshold = 85.0;
  @override
  Widget build(BuildContext context) => AppShell(
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
                              selected: roles.contains(role),
                              onSelected: (value) => setState(
                                () => value
                                    ? roles.add(role)
                                    : roles.remove(role),
                              ),
                            ),
                          )
                          .toList()
                        ..add(const PillChip(label: '+ Custom')),
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
                  selected: jobType,
                  onSelected: (value) => setState(() => jobType = value),
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
                  selected: workMode,
                  onSelected: (value) => setState(() => workMode = value),
                ),
                const Divider(height: 42),
                const _PreferenceTitle(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Expected Stipend/Salary',
                  subtitle: 'Adjust your minimum monthly expectations.',
                ),
                const SizedBox(height: AppSpacing.sm),
                _SalaryCard(
                  value: salary,
                  onChanged: (value) => setState(() => salary = value),
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
                  children: locations
                      .map(
                        (location) => InputChip(
                          label: Text(location),
                          onDeleted: () =>
                              setState(() => locations.remove(location)),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Add another city...',
                    prefixIcon: Icon(Icons.location_on_outlined),
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
                  value: threshold,
                  onChanged: (value) => setState(() => threshold = value),
                ),
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
            label: 'Save Preferences',
            trailing: const Icon(Icons.arrow_forward_rounded),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.home),
          ),
        ),
      ],
    ),
  );
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
