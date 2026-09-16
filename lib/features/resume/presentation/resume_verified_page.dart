import 'package:flutter/material.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_chips.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';

class ResumeVerifiedPage extends StatelessWidget {
  const ResumeVerifiedPage({super.key});
  @override
  Widget build(BuildContext context) => AppShell(
    navigationVariant: AppNavigationVariant.hunter,
    selectedIndex: 3,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      child: Column(
        children: [
          const _VerifiedIllustration(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Resume Verified',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontFamily: 'serif'),
          ),
          Text(
            'Our AI has finished scanning your\nprofessional profile.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _ResumeSummary(),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Continue to Job Sources',
            trailing: const Icon(Icons.arrow_forward_rounded),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.jobSources),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '▪  Step 2 of 4: Profile Setup  ▪',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSurface(
            shadows: const [],
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.warning,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Want higher match scores? Try adding specific project keywords.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _VerifiedIllustration extends StatelessWidget {
  const _VerifiedIllustration();
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: 92,
        height: 112,
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: AppRadii.large,
          boxShadow: AppShadows.card,
        ),
        child: const Icon(
          Icons.description_outlined,
          size: 50,
          color: AppColors.primary,
        ),
      ),
      const Positioned(
        bottom: 12,
        right: 4,
        child: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.success,
          child: Icon(Icons.check, color: Colors.white, size: 27),
        ),
      ),
    ],
  );
}

class _ResumeSummary extends StatelessWidget {
  const _ResumeSummary();
  @override
  Widget build(BuildContext context) => AppSurface(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: AppRadii.small,
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Benedict_Joseph_Resume',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: StatusBadge(label: 'Successfully analyzed'),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh, size: 17),
                label: const Text('Replace'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SummarySection(
                icon: Icons.code,
                title: 'EXTRACTED SKILLS',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Identified core competencies across\nfrontend and backend development.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Wrap(
                spacing: 14,
                runSpacing: 10,
                children: [
                  Text('React'),
                  Text('JavaScript'),
                  Text('TypeScript'),
                  Text('TailwindCSS'),
                  Text('Node.js'),
                  Text('Python'),
                  Text('UI/UX Design'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SummarySection(
                icon: Icons.business_center_outlined,
                title: 'PROFESSIONAL EXPERIENCE',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Senior Frontend Engineer at TechFlow\nSolutions (4+ years)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SummarySection(
                icon: Icons.school_outlined,
                title: 'ACADEMIC BACKGROUND',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'M.S. in Computer Science, Stanford\nUniversity',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSurface(
                color: AppColors.primarySoft,
                borderColor: AppColors.border,
                shadows: const [],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI SUMMARY',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '"Expert in building scalable React applications with a focus on performance and premium user experience."',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF315483),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: AppRadii.small,
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      const SizedBox(width: AppSpacing.sm),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(letterSpacing: .5),
      ),
    ],
  );
}
