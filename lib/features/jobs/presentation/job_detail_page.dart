import 'package:flutter/material.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_chips.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/content_widgets.dart';
import '../data/mock_jobs.dart';

class JobDetailPage extends StatefulWidget {
  const JobDetailPage({super.key});
  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  var saved = false;
  @override
  Widget build(BuildContext context) => AppShell(
    navigationVariant: AppNavigationVariant.hunter,
    selectedIndex: 1,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    tooltip: 'Share job',
                    icon: const Icon(Icons.share_outlined),
                  ),
                  IconButton(
                    onPressed: () => setState(() => saved = !saved),
                    tooltip: saved ? 'Remove bookmark' : 'Bookmark job',
                    icon: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_border,
                      color: saved ? AppColors.primary : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: AppRadii.large,
                  ),
                  child: const Icon(
                    Icons.code_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                softwareEngineerIntern.title,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontFamily: 'serif'),
              ),
              const SizedBox(height: 4),
              Text(
                'ABC Technologies  •  Posted 2 days ago',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TagChip(label: 'Bangalore, India'),
                  TagChip(label: 'Hybrid', color: AppColors.successSoft),
                  TagChip(label: '₹40k - ₹60k / month'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const MatchScoreCard(
                score: 94,
                label: 'AI Skill Analysis',
                message:
                    '“A strong fit: your frontend skills and project experience closely match this internship.”',
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'About the Role',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "Join ABC Technologies’ core engineering team as a Software Engineer Intern. You'll work on building scalable microservices and enhancing our AI-driven productivity suite. This is a high-impact role with mentorship from senior architects.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Requirements',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              _Checklist(items: softwareEngineerIntern.requirements),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Skills Match',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _SkillsGrid(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Growth opportunities',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _Improvement(
                label: 'GraphQL',
                note: 'Low impact',
                icon: Icons.trending_flat,
              ),
              const _Improvement(
                label: 'Docker',
                note: 'Learnable',
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Applications close in 5 days',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SecondaryOutlinedButton(
                  label: 'Tailor Resume',
                  leading: const Icon(Icons.auto_awesome_outlined),
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.optimizationReady),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PrimaryButton(
                  label: 'Apply Now',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'External application integration will be implemented later.',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.items});
  final List<String> items;
  @override
  Widget build(BuildContext context) => Column(
    children: items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}

class _SkillsGrid extends StatelessWidget {
  const _SkillsGrid();
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    childAspectRatio: 2.15,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    children: internSkillMatches
        .map((skill) => _Skill(name: skill.name, score: skill.score))
        .toList(),
  );
}

class _Skill extends StatelessWidget {
  const _Skill({required this.name, required this.score});
  final String name;
  final int score;
  @override
  Widget build(BuildContext context) => AppSurface(
    shadows: const [],
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name, style: Theme.of(context).textTheme.titleSmall),
            ),
            Text('$score%', style: const TextStyle(color: AppColors.success)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: score / 100,
          minHeight: 5,
          borderRadius: AppRadii.pill,
          color: AppColors.success,
          backgroundColor: AppColors.successSoft,
        ),
      ],
    ),
  );
}

class _Improvement extends StatelessWidget {
  const _Improvement({
    required this.label,
    required this.note,
    required this.icon,
  });
  final String label, note;
  final IconData icon;
  @override
  Widget build(BuildContext context) => AppSurface(
    shadows: const [],
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        TagChip(label: note),
      ],
    ),
  );
}
