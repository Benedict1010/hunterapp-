import 'package:flutter/material.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_chips.dart';
import '../../../core/widgets/app_surface.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Brand(),
            const SizedBox(height: AppSpacing.md),
            const _HeroIllustration(),
            const SizedBox(height: AppSpacing.xl),
            const Wrap(
              spacing: AppSpacing.xs,
              children: [
                TagChip(label: 'Privacy Guaranteed'),
                TagChip(label: 'AI-Powered'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your AI Job Search,',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            Text(
              'Automated.',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.primary,
                fontStyle: FontStyle.italic,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Find jobs that match your skills, tailor your resume with AI, and apply faster than ever before.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _BenefitsCard(),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Get Started',
              trailing: const Icon(Icons.arrow_forward_rounded),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.resumeVerified),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: () {},
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: const [
                      TextSpan(text: 'Already have an account?  '),
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: '  ›'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadii.small,
        ),
        child: const Icon(
          Icons.business_center_outlined,
          color: Colors.white,
          size: 20,
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      Text('AI Job Hunter', style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        height: 255,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF93D9F3), Color(0xFF463676)],
          ),
          boxShadow: AppShadows.card,
        ),
        child: Stack(
          children: [
            const Positioned(
              left: 24,
              bottom: 42,
              child: Icon(
                Icons.business_center,
                color: Colors.white70,
                size: 72,
              ),
            ),
            const Center(
              child: Icon(
                Icons.psychology_outlined,
                color: Colors.white,
                size: 104,
              ),
            ),
            const Positioned(
              right: 34,
              top: 76,
              child: Icon(
                Icons.search_rounded,
                color: Colors.white70,
                size: 62,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: .32),
                      Colors.transparent,
                    ],
                    radius: .72,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      Positioned(
        right: 10,
        bottom: -14,
        child: StatusBadge(
          label: '98% AI Match',
          color: AppColors.success,
          icon: Icons.auto_awesome,
        ),
      ),
    ],
  );
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();
  @override
  Widget build(BuildContext context) => AppSurface(
    shadows: const [],
    child: Column(
      children: const [
        _Benefit(
          icon: Icons.track_changes_outlined,
          title: 'Hyper-Personalized Matching',
          description:
              'Our AI scans thousands of listings to find the perfect technical and cultural fit.',
        ),
        Divider(height: 28),
        _Benefit(
          icon: Icons.auto_awesome_outlined,
          title: 'AI Resume Tailoring',
          description:
              'Automatically optimize your profile for each specific role to beat the ATS.',
        ),
      ],
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
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
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    ],
  );
}
