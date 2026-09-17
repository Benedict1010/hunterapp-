import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';

class TailoredResumePage extends StatelessWidget {
  const TailoredResumePage({super.key});
  @override
  Widget build(BuildContext context) => AppShell(
    navigationVariant: AppNavigationVariant.optimize,
    selectedIndex: 0,
    title: 'Tailored Resume',
    showNotificationAction: false,
    child: Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tailored Resume', style: TextStyle(fontSize: 0)),
                      Text(
                        'Software Engineer Role',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _feedback(context, 'Sharing will be available later.'),
                  tooltip: 'Share',
                  icon: const Icon(Icons.share_outlined),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const _AiCallout(),
            const _PreviewCard(),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text(
                  'Recent Changes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _feedback(
                    context,
                    'All changes are shown in this prototype.',
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
            const _ChangeRow(
              icon: Icons.description_outlined,
              title: 'Skills Alignment',
              subtitle: 'Added 4 relevant keywords from JD',
            ),
            const SizedBox(height: AppSpacing.sm),
            const _ChangeRow(
              icon: Icons.auto_awesome_outlined,
              title: 'Summary Refinement',
              subtitle: 'Tailored for Senior role emphasis',
            ),
          ],
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: FloatingActionButton(
            onPressed: () =>
                _feedback(context, 'Download will be available later.'),
            child: const Icon(Icons.download_outlined),
          ),
        ),
      ],
    ),
  );
}

void _feedback(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

class _AiCallout extends StatelessWidget {
  const _AiCallout();
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
            const Icon(Icons.auto_awesome, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'AI Tailored Optimization',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
              ),
            ),
            const Chip(label: Text('High Match')),
          ],
        ),
        const Text(
          'MATCH SCORE: 94%',
          style: TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "We've emphasized your React.js and System Design experience to align with the Lead Developer requirements.",
        ),
      ],
    ),
  );
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard();
  @override
  Widget build(BuildContext context) => AppSurface(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            '●  VERSION 2.4 • UPDATED JUST NOW',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.zoom_out, color: AppColors.textSecondary),
              const SizedBox(width: 16),
              const Text('85%'),
              const Spacer(),
              Flexible(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Export'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 400,
          color: AppColors.primarySoft,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.all(18),
          child: Container(
            width: 160,
            height: 210,
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'ANNUAL PROJECT REPORT',
                    style: TextStyle(fontSize: 5, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '1. Executive Summary\n\nBuilt scalable web features and improved user experiences through thoughtful engineering.\n\n2. Professional Experience\n\n• React and TypeScript\n• System design\n• CI/CD pipelines',
                  style: TextStyle(fontSize: 5, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'PAGE 1 OF 2',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => AppSurface(
    shadows: const [],
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.surfaceSubtle,
          child: Icon(icon, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}
