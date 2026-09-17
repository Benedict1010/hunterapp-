import 'package:flutter/material.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_chips.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../data/mock_applications.dart';
import '../domain/job_application.dart';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({super.key});
  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  var _status = ApplicationStatus.applied;
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applications = mockApplications
        .where(
          (item) =>
              item.status == _status &&
              (item.title.toLowerCase().contains(_search.text.toLowerCase()) ||
                  item.company.toLowerCase().contains(
                    _search.text.toLowerCase(),
                  )),
        )
        .toList();
    return AppShell(
      navigationVariant: AppNavigationVariant.optimize,
      selectedIndex: 1,
      child: Stack(
        children: [
          ListView(
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
                onChanged: (value) => setState(() => _status = value),
              ),
              const Divider(height: 24),
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
                _ApplicationCard(application: application),
              if (applications.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No applications found.')),
                ),
            ],
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: FloatingActionButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Adding applications will be available later.'),
                ),
              ),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({required this.selected, required this.onChanged});
  final ApplicationStatus selected;
  final ValueChanged<ApplicationStatus> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final item in ApplicationStatus.values)
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
  String _label(ApplicationStatus value) => switch (value) {
    ApplicationStatus.applied => 'Applied  1',
    ApplicationStatus.interviewing => 'Interviewing  1',
    ApplicationStatus.offered => 'Offered  1',
  };
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});
  final JobApplication application;
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
              label: _statusLabel(application.status),
              color: AppColors.primarySoft,
            ),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.applicationDetails),
              child: const Text('View Details  ›'),
            ),
          ],
        ),
      ],
    ),
  );
  String _statusLabel(ApplicationStatus value) => switch (value) {
    ApplicationStatus.applied => 'Applied',
    ApplicationStatus.interviewing => 'Interviewing',
    ApplicationStatus.offered => 'Offered',
  };
}
