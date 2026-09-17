import 'package:flutter/material.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_chips.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../data/mock_jobs.dart';
import '../domain/job.dart';

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
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<JobMatch> get _matches {
    final query = _search.text.toLowerCase();
    final result = jobMatches.where((match) {
      final searched =
          query.isEmpty ||
          match.job.title.toLowerCase().contains(query) ||
          match.job.company.toLowerCase().contains(query);
      final filtered = switch (_filter) {
        'Design' =>
          match.job.title.contains('Product') || match.job.title.contains('UI'),
        'Remote' => match.job.workMode == 'Remote',
        _ => true,
      };
      return searched && filtered;
    }).toList();
    result.sort(
      (a, b) =>
          _descending ? b.score.compareTo(a.score) : a.score.compareTo(b.score),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    return AppShell(
      navigationVariant: AppNavigationVariant.hunter,
      selectedIndex: 1,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '3 PREMIUM MATCHES FOUND',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: .7,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _descending = !_descending),
                icon: const Icon(Icons.swap_vert, size: 18),
                label: const Text('Sort by: Match %'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final match in matches) ...[
            _JobCard(
              match: match,
              saved: _saved.contains(match.job.id),
              onSaved: () => setState(
                () => _saved.contains(match.job.id)
                    ? _saved.remove(match.job.id)
                    : _saved.add(match.job.id),
              ),
              onView: () =>
                  Navigator.of(context).pushNamed(AppRoutes.jobDetail),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (matches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: Text('No matching jobs found.')),
            ),
          const SizedBox(height: AppSpacing.lg),
          const _AdjustCriteriaPrompt(),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.match,
    required this.saved,
    required this.onSaved,
    required this.onView,
  });
  final JobMatch match;
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
                    match.job.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    match.job.company,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                StatusBadge(label: '${match.score}% Match'),
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
        _Detail(icon: Icons.location_on_outlined, label: match.job.location),
        const SizedBox(height: 6),
        _Detail(
          icon: Icons.attach_money_rounded,
          label: match.job.compensation,
        ),
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
                '“${match.rationale}”',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: match.tags.map((tag) => TagChip(label: tag)).toList(),
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
