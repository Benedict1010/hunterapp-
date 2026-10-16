import 'package:flutter/material.dart';

import '../../../app/job_source_scope.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/content_widgets.dart';
import 'job_source_controller.dart';

class JobSourcesPage extends StatefulWidget {
  const JobSourcesPage({super.key});
  @override
  State<JobSourcesPage> createState() => _JobSourcesPageState();
}

class _JobSourcesPageState extends State<JobSourcesPage> {
  final fallbackSelected = <String>{};
  final fallbackPlatforms = const [
    _Platform(
      'LinkedIn',
      'Professional network\nwith global high-end',
      Icons.badge_outlined,
      isAvailable: false,
    ),
    _Platform(
      'Unstop',
      'Hub for student\ncompetitions,',
      Icons.workspace_premium_outlined,
      isAvailable: false,
    ),
    _Platform(
      'Naukri',
      'Massive database of\njobs across diverse',
      Icons.work_outline,
      isAvailable: false,
    ),
    _Platform(
      'Internshala',
      'Leading platform for\ninternships and',
      Icons.school_outlined,
      isAvailable: false,
    ),
    _Platform(
      'Indeed',
      'Aggregated job board\ncovering local and',
      Icons.search_outlined,
      isAvailable: false,
    ),
    _Platform(
      'Career Pages',
      'Direct AI-tracking of\nspecific top-tier',
      Icons.account_balance_outlined,
      isAvailable: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = JobSourceScope.maybeOf(context);
      if (controller != null &&
          controller.status == JobSourceStateStatus.initial) {
        controller.loadSources();
      }
    });
  }

  IconData _iconForName(String name) => switch (name) {
    'LinkedIn' => Icons.badge_outlined,
    'Unstop' => Icons.workspace_premium_outlined,
    'Naukri' => Icons.work_outline,
    'Internshala' => Icons.school_outlined,
    'Indeed' => Icons.search_outlined,
    'Career Pages' => Icons.account_balance_outlined,
    _ => Icons.grid_view_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final controller = JobSourceScope.maybeOf(context);

    final List<_Platform> platforms;
    final int selectedCount;

    if (controller != null && controller.sources.isNotEmpty) {
      platforms = controller.sources
          .map(
            (s) => _Platform(
              s.name,
              s.description ?? 'Job source integration platform',
              _iconForName(s.name),
              id: s.id,
              isAvailable: s.isAvailable,
            ),
          )
          .toList();
      selectedCount = controller.selectedIds.length;
    } else {
      platforms = fallbackPlatforms;
      selectedCount = fallbackSelected.length;
    }

    return AppShell(
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
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
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
                    title: 'Source preferences',
                    message:
                        'Your selection is saved to your account. Only sources marked Available can currently provide jobs; external sources are not automatically synchronized.',
                    icon: Icons.search,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (controller != null && controller.isLoading) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: AppSpacing.xl),
                  ] else if (controller != null && controller.hasError) ...[
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
                                'Failed to load job sources.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ElevatedButton.icon(
                            onPressed: () => controller.loadSources(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ] else ...[
                    Row(
                      children: [
                        Text(
                          'AVAILABLE PLATFORMS',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                letterSpacing: .6,
                              ),
                        ),
                        const Spacer(),
                        _CountBadge(count: selectedCount),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: platforms.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: .67,
                          ),
                      itemBuilder: (_, index) {
                        final platform = platforms[index];
                        final isSelected = controller != null
                            ? (platform.id != null
                                  ? controller.isSelected(platform.id!)
                                  : controller.isSelectedByName(platform.name))
                            : fallbackSelected.contains(platform.name);

                        return _PlatformCard(
                          platform: platform,
                          selected: isSelected,
                          onChanged: (value) {
                            if (controller != null) {
                              if (platform.id != null) {
                                controller.toggleSource(platform.id!);
                              } else {
                                controller.toggleSourceByName(platform.name);
                              }
                            } else {
                              setState(() {
                                if (value) {
                                  fallbackSelected.add(platform.name);
                                } else {
                                  fallbackSelected.remove(platform.name);
                                }
                              });
                            }
                          },
                        );
                      },
                    ),
                  ],
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
                  label: controller != null && controller.isSaving
                      ? 'Saving...'
                      : 'Continue',
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onPressed: controller != null && controller.isSaving
                      ? null
                      : () async {
                          if (controller != null) {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await controller.saveSelections();
                            if (success && mounted) {
                              navigator.pushNamed(AppRoutes.preferences);
                            } else if (mounted && controller.hasError) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    controller.errorMessage ??
                                        'Failed to save sources.',
                                  ),
                                ),
                              );
                            }
                          } else {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.preferences);
                          }
                        },
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
}

class _Platform {
  const _Platform(
    this.name,
    this.description,
    this.icon, {
    this.id,
    this.isAvailable = false,
  });
  final String? id;
  final String name;
  final String description;
  final IconData icon;
  final bool isAvailable;
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

  String get _statusLabel {
    if (selected && platform.isAvailable) return 'Active Sync';
    if (selected && !platform.isAvailable) return 'Sync Unavailable';
    if (!selected && platform.isAvailable) return 'Live Adapter';
    return 'Discovery';
  }

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
                Expanded(
                  child: Text(
                    platform.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
                _statusLabel,
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
