import 'package:flutter/material.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/content_widgets.dart';

class JobSourcesPage extends StatefulWidget {
  const JobSourcesPage({super.key});
  @override
  State<JobSourcesPage> createState() => _JobSourcesPageState();
}

class _JobSourcesPageState extends State<JobSourcesPage> {
  final selected = <String>{'LinkedIn', 'Unstop'};
  final platforms = const [
    _Platform(
      'LinkedIn',
      'Professional network\nwith global high-end',
      Icons.badge_outlined,
    ),
    _Platform(
      'Unstop',
      'Hub for student\ncompetitions,',
      Icons.workspace_premium_outlined,
    ),
    _Platform(
      'Naukri',
      'Massive database of\njobs across diverse',
      Icons.work_outline,
    ),
    _Platform(
      'Internshala',
      'Leading platform for\ninternships and',
      Icons.school_outlined,
    ),
    _Platform(
      'Indeed',
      'Aggregated job board\ncovering local and',
      Icons.search_outlined,
    ),
    _Platform(
      'Career Pages',
      'Direct AI-tracking of\nspecific top-tier',
      Icons.account_balance_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) => AppShell(
    navigationVariant: AppNavigationVariant.hunter,
    selectedIndex: 1,
    child: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 46,
                      child: Divider(color: AppColors.primary, thickness: 3),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'STEP 2 OF 4',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        letterSpacing: .6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Choose Job Sources',
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall?.copyWith(fontFamily: 'serif'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select the platforms where you want our AI agent to hunt for your perfect role. More sources lead to better discovery.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                const InfoCallout(
                  title: 'Smart Scanning Enabled',
                  message:
                      'Our AI will automatically sync with your selected sources to track applications and match scores in real-time.',
                  icon: Icons.search,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text(
                      'AVAILABLE PLATFORMS',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: .6,
                      ),
                    ),
                    const Spacer(),
                    _CountBadge(count: selected.length),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: platforms.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: .67,
                  ),
                  itemBuilder: (_, index) {
                    final platform = platforms[index];
                    return _PlatformCard(
                      platform: platform,
                      selected: selected.contains(platform.name),
                      onChanged: (value) => setState(
                        () => value
                            ? selected.add(platform.name)
                            : selected.remove(platform.name),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                SecondaryOutlinedButton(
                  label: 'Add Custom Domain',
                  leading: const Icon(Icons.add),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              PrimaryButton(
                label: 'Continue',
                trailing: const Icon(Icons.arrow_forward_rounded),
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.preferences),
              ),
              const SizedBox(height: 6),
              Text(
                'You can change these sources later in Settings',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Platform {
  const _Platform(this.name, this.description, this.icon);
  final String name;
  final String description;
  final IconData icon;
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: const BoxDecoration(
      color: AppColors.surfaceSubtle,
      borderRadius: AppRadii.pill,
    ),
    child: Text(
      '$count Selected',
      style: Theme.of(context).textTheme.labelMedium,
    ),
  );
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.platform,
    required this.selected,
    required this.onChanged,
  });
  final _Platform platform;
  final bool selected;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primarySoft : AppColors.border,
          ),
          borderRadius: AppRadii.medium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadii.small,
                  ),
                  child: Icon(
                    platform.icon,
                    color: AppColors.primary,
                    size: 23,
                  ),
                ),
                const Spacer(),
                Switch(value: selected, onChanged: onChanged),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  platform.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (selected)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.check,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              platform.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            const Divider(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadii.pill,
              ),
              child: Text(
                selected ? 'Active Sync' : 'Discovery',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w400),
              ),
            ),
          ],
        ),
      ),
      if (selected)
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Text(
              'TOP MATCH',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontSize: 9,
              ),
            ),
          ),
        ),
    ],
  );
}
