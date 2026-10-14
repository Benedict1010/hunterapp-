import 'package:flutter/material.dart';

import '../../../app/application_scope.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_chips.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../domain/job_application.dart';
import 'application_controller.dart';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({super.key});

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  var _status = ApplicationStatus.applied;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ApplicationScope.maybeOf(context);
      if (controller != null &&
          controller.status == ApplicationStateStatus.initial) {
        controller.loadApplications();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Application> _filteredApplications(List<Application> allApps) {
    final query = _search.text.toLowerCase().trim();
    return allApps.where((item) {
      final matchesStatus =
          item.status == _status ||
          (_status == ApplicationStatus.interview &&
              item.status == ApplicationStatus.interview) ||
          (_status == ApplicationStatus.offer &&
              item.status == ApplicationStatus.offer);

      final matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.company.toLowerCase().contains(query);

      return matchesStatus && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ApplicationScope.maybeOf(context);

    return AppShell(
      navigationVariant: AppNavigationVariant.optimize,
      selectedIndex: 1,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              if (controller != null) {
                await controller.loadApplications();
              }
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Applications',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      tooltip: 'Filter applications',
                      icon: const Icon(Icons.filter_alt_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search applications...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _StatusTabs(
                  selected: _status,
                  applications: controller?.applications ?? [],
                  onChanged: (value) => setState(() => _status = value),
                ),
                const Divider(height: 24),
                if (controller != null && controller.isLoading) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: AppSpacing.xl),
                ] else if (controller != null && controller.hasError) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppSurface(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.warning,
                          size: 40,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          controller.errorMessage ??
                              'Failed to load applications.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: () => controller.loadApplications(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Builder(
                    builder: (context) {
                      final allApps = controller?.applications ?? [];
                      final applications = _filteredApplications(allApps);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${applications.length} JOBS FOUND',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                child: const Text('Newest first'),
                              ),
                            ],
                          ),
                          for (final application in applications)
                            _ApplicationCard(
                              application: application,
                              onTap: () {
                                controller?.selectApplication(application);
                                Navigator.of(context).pushNamed(
                                  AppRoutes.applicationDetails,
                                  arguments: application.id,
                                );
                              },
                            ),
                          if (applications.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text('No applications found.'),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: FloatingActionButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.jobs),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.selected,
    required this.applications,
    required this.onChanged,
  });

  final ApplicationStatus selected;
  final List<Application> applications;
  final ValueChanged<ApplicationStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final statuses = [
      ApplicationStatus.applied,
      ApplicationStatus.interview,
      ApplicationStatus.offer,
    ];

    return Row(
      children: [
        for (final item in statuses)
          Expanded(
            child: TextButton(
              onPressed: () => onChanged(item),
              child: Text(
                _label(item),
                style: TextStyle(
                  color: selected == item
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _label(ApplicationStatus value) {
    final count = applications.where((a) => a.status == value).length;
    return '${value.label}  $count';
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application, required this.onTap});

  final Application application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(application.title, style: Theme.of(context).textTheme.titleLarge),
        Text(application.company),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 17),
            const SizedBox(width: 6),
            Expanded(child: Text(application.location)),
            StatusBadge(label: '${application.matchScore}% Match'),
          ],
        ),
        const Divider(height: 28),
        Row(
          children: [
            TagChip(
              label: application.status.label,
              color: AppColors.primarySoft,
            ),
            const Spacer(),
            TextButton(onPressed: onTap, child: const Text('View Details  ›')),
          ],
        ),
      ],
    ),
  );
}
