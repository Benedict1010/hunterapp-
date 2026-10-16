import 'package:flutter/material.dart';

import '../../../app/job_scope.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_chips.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../domain/job.dart';
import '../domain/job_match.dart';
import 'job_controller.dart';

class JobsForYouPage extends StatefulWidget {
  const JobsForYouPage({super.key});

  @override
  State<JobsForYouPage> createState() => _JobsForYouPageState();
}

class _JobsForYouPageState extends State<JobsForYouPage> {
  final _search = TextEditingController();
  final _saved = <String>{};
  var _filter = 'All Matches';
  var _descending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = JobScope.maybeOf(context);
      if (controller != null) {
        if (controller.status == JobStateStatus.initial) {
          controller.loadJobs();
        }
        controller.loadUserMatches();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Job> _filteredJobs(List<Job> jobs, Map<String, JobMatch> matches) {
    final query = _search.text.toLowerCase().trim();
    final result = jobs.where((job) {
      final matchesQuery =
          query.isEmpty ||
          job.title.toLowerCase().contains(query) ||
          job.company.toLowerCase().contains(query);

      final matchesFilter = switch (_filter) {
        'Design' =>
          job.title.toLowerCase().contains('design') ||
              job.title.toLowerCase().contains('ui') ||
              job.title.toLowerCase().contains('product'),
        'Remote' => job.location?.toLowerCase().contains('remote') ?? false,
        'Over \$120K' =>
          job.salaryRange != null &&
              (job.salaryRange!.contains('120') ||
                  job.salaryRange!.contains('150')),
        _ => true,
      };

      return matchesQuery && matchesFilter;
    }).toList();

    result.sort((a, b) {
      final scoreA = matches[a.id]?.score ?? 0;
      final scoreB = matches[b.id]?.score ?? 0;
      return _descending ? scoreB.compareTo(scoreA) : scoreA.compareTo(scoreB);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final controller = JobScope.maybeOf(context);

    return AppShell(
      navigationVariant: AppNavigationVariant.hunter,
      selectedIndex: 1,
      child: RefreshIndicator(
        onRefresh: () async {
          if (controller != null) {
            await controller.loadJobs();
            await controller.loadUserMatches();
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
          children: [
            Text(
              'Jobs For You',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontFamily: 'serif'),
            ),
            const SizedBox(height: 4),
            Text(
              'AI-curated opportunities based on your profile',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search job titles or companies...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  onPressed: () {},
                  tooltip: 'Filter jobs',
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All Matches', 'Design', 'Remote', 'Over \$120K']
                    .map(
                      (filter) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: PillChip(
                          label: filter,
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (controller != null && controller.isLoadingJobs) ...[
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
                      controller.errorMessage ?? 'Failed to load jobs.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton.icon(
                      onPressed: () => controller.loadJobs(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Builder(
                builder: (context) {
                  final allJobs = controller?.jobs ?? [];
                  final matches = controller?.matchesByJobId ?? {};
                  final jobs = _filteredJobs(allJobs, matches);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${jobs.length} MATCHES FOUND',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    letterSpacing: .7,
                                  ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _descending = !_descending),
                            icon: const Icon(Icons.swap_vert, size: 18),
                            label: const Text('Sort by: Match %'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (jobs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.work_off_outlined,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'No matching jobs found.',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Try clearing your search or filters.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                OutlinedButton(
                                  onPressed: () {
                                    _search.clear();
                                    setState(() => _filter = 'All Matches');
                                    controller?.loadJobs();
                                  },
                                  child: const Text('Reset Search'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        for (final job in jobs) ...[
                          _JobCard(
                            job: job,
                            match: matches[job.id],
                            saved: _saved.contains(job.id),
                            onSaved: () => setState(
                              () => _saved.contains(job.id)
                                  ? _saved.remove(job.id)
                                  : _saved.add(job.id),
                            ),
                            onView: () {
                              controller?.selectJob(job);
                              Navigator.of(context).pushNamed(
                                AppRoutes.jobDetail,
                                arguments: job.id,
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            const _AdjustCriteriaPrompt(),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    this.match,
    required this.saved,
    required this.onSaved,
    required this.onView,
  });

  final Job job;
  final JobMatch? match;
  final bool saved;
  final VoidCallback onSaved, onView;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadii.small,
              ),
              child: const Icon(
                Icons.business_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    job.company,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                if (match != null)
                  StatusBadge(label: '${match!.score}% Match')
                else if (job.source.isNotEmpty)
                  StatusBadge(label: job.source),
                IconButton(
                  onPressed: onSaved,
                  tooltip: saved ? 'Remove bookmark' : 'Bookmark job',
                  icon: Icon(
                    saved ? Icons.bookmark : Icons.bookmark_border,
                    color: saved ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _Detail(icon: Icons.location_on_outlined, label: job.locationLabel),
        if (job.salaryRange != null && job.salaryRange!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _Detail(icon: Icons.attach_money_rounded, label: job.compensation),
        ],
        if (match?.explanation != null && match!.explanation!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          AppSurface(
            color: AppColors.surfaceSubtle,
            shadows: const [],
            borderColor: Colors.transparent,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHY IT MATCHES',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '“${match!.explanation}”',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (job.source.isNotEmpty) TagChip(label: job.source),
                  ...job.skills
                      .take(3)
                      .map((skill) => TagChip(label: skill.name)),
                ],
              ),
            ),
            TextButton(onPressed: onView, child: const Text('View Job  ›')),
          ],
        ),
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 4),
      Expanded(
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
    ],
  );
}

class _AdjustCriteriaPrompt extends StatelessWidget {
  const _AdjustCriteriaPrompt();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const CircleAvatar(
        backgroundColor: AppColors.surfaceSubtle,
        child: Icon(Icons.tune_rounded, color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Adjust your criteria?',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 4),
      const Text(
        'Fine-tune your job preferences to discover\nmore tailored opportunities.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.preferences),
          child: const Text('Edit Preferences  →'),
        ),
      ),
    ],
  );
}
