import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../app/auth_scope.dart';
import '../../../app/resume_scope.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_chips.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/content_widgets.dart';
import '../../resume/domain/resume.dart';
import '../../resume/presentation/resume_controller.dart';
import '../data/mock_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var _provider = 'Lumina GPT-4o';
  var _pushNotifications = true;
  var _autoOptimization = false;
  var _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final resumeController = ResumeScope.maybeOf(context);
          if (resumeController != null &&
              resumeController.status == ResumeStateStatus.initial) {
            resumeController.loadResumes();
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => AppShell(
    navigationVariant: AppNavigationVariant.optimize,
    selectedIndex: 3,
    showNotificationAction: false,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Account Profile',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            IconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.settings),
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Stack(
            children: [
              const CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primarySoft,
                child: Icon(Icons.person, size: 55, color: AppColors.primary),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    onPressed: () => _message(
                      'Profile photo editing is not available in this local preview.',
                    ),
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 17,
                    ),
                    tooltip: 'Edit profile photo',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          mockProfile.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          mockProfile.email,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        const Center(child: _RoleBadge()),
        const SizedBox(height: 22),
        Row(
          children: [
            for (final stat in mockProfile.stats)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AppSurface(
                    shadows: const [],
                    child: Column(
                      children: [
                        Text(
                          stat.value,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          stat.label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 26),
        const _ResumeSection(),
        const SizedBox(height: 26),
        Text(
          'AI PROVIDER',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        _ProviderCard(
          name: 'Lumina GPT-4o',
          detail: 'Best for Resumes',
          selected: _provider == 'Lumina GPT-4o',
          premium: true,
          onTap: () => setState(() => _provider = 'Lumina GPT-4o'),
        ),
        const SizedBox(height: 10),
        _ProviderCard(
          name: 'Claude 3.5 Sonnet',
          detail: 'Thoughtful career guidance',
          selected: _provider == 'Claude 3.5 Sonnet',
          onTap: () => setState(() => _provider = 'Claude 3.5 Sonnet'),
        ),
        const SizedBox(height: 24),
        Text(
          'MANAGE ACCOUNT',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
        ),
        AppSurface(
          shadows: const [],
          child: Column(
            children: [
              SettingsRow(
                title: 'Personal Information',
                leading: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                ),
                onTap: () => _message(
                  'Personal information editing is not available in this local preview.',
                ),
              ),
              const Divider(),
              SettingsRow(
                title: 'Job Preferences',
                leading: const Icon(Icons.tune, color: AppColors.primary),
                onTap: () => Navigator.of(context).pushNamed('/preferences'),
              ),
              const Divider(),
              SettingsRow(
                title: 'App Language',
                subtitle: 'English',
                leading: const Icon(Icons.language, color: AppColors.primary),
                onTap: () => _message(
                  'Language selection is not available in this local preview.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'PREFERENCES',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
        ),
        AppSurface(
          shadows: const [],
          child: Column(
            children: [
              SettingsRow(
                title: 'Push Notifications',
                leading: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                ),
                trailing: Switch(
                  value: _pushNotifications,
                  onChanged: (value) =>
                      setState(() => _pushNotifications = value),
                ),
              ),
              const Divider(),
              SettingsRow(
                title: 'Auto-Optimization',
                leading: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.primary,
                ),
                trailing: Switch(
                  value: _autoOptimization,
                  onChanged: (value) =>
                      setState(() => _autoOptimization = value),
                ),
              ),
              const Divider(),
              SettingsRow(
                title: 'Security & Privacy',
                leading: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                ),
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.settings),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TextButton.icon(
          onPressed: () async {
            final authController = AuthScope.maybeOf(context);
            if (authController != null && authController.isAuthenticated) {
              final navigator = Navigator.of(context);
              await authController.logout();
              navigator.pushNamedAndRemoveUntil(
                AppRoutes.landing,
                (route) => false,
              );
            } else {
              _message('Signed out successfully.');
            }
          },
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text(
            'Sign Out',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'AI Job Hunter v1.0.0',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _ResumeSection extends StatelessWidget {
  const _ResumeSection();

  Future<void> _pickAndUpload(BuildContext context, ResumeController controller) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
      );
      if (result.isNotEmpty) {
        final file = result.first;
        final bytes = file.path == null ? await file.readAsBytes() : null;
        final uploaded = await controller.uploadResume(
          filePath: file.path ?? '',
          fileName: file.name,
          bytes: bytes,
        );
        if (context.mounted) {
          if (uploaded != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Uploaded ${uploaded.filename} successfully.')),
            );
          } else if (controller.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(controller.errorMessage!)),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUpdate(BuildContext context, ResumeController controller, String resumeId) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
      );
      if (result.isNotEmpty) {
        final file = result.first;
        final bytes = file.path == null ? await file.readAsBytes() : null;
        final updated = await controller.updateResume(
          resumeId,
          filePath: file.path ?? '',
          fileName: file.name,
          bytes: bytes,
        );
        if (context.mounted) {
          if (updated != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Updated ${updated.filename} successfully.')),
            );
          } else if (controller.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(controller.errorMessage!)),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, ResumeController controller, Resume resume) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Resume'),
        content: Text('Are you sure you want to delete "${resume.filename}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await controller.deleteResume(resume.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted ${resume.filename}.')),
          );
        } else if (controller.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(controller.errorMessage!)),
          );
        }
      }
    }
  }

  Future<void> _download(BuildContext context, ResumeController controller, Resume resume) async {
    final bytes = await controller.downloadResume(resume.id);
    if (context.mounted) {
      if (bytes != null && bytes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded ${resume.filename} (${bytes.length} bytes)')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage ?? 'Download failed.')),
        );
      }
    }
  }

  Future<void> _extract(BuildContext context, ResumeController controller, Resume resume) async {
    final updated = await controller.extractResume(resume.id);
    if (context.mounted) {
      if (updated != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume text re-extracted successfully.')),
        );
      } else if (controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage!)),
        );
      }
    }
  }

  Future<void> _setPrimary(BuildContext context, ResumeController controller, Resume resume) async {
    final success = await controller.setPrimary(resume.id);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${resume.filename} is now primary.')),
        );
      } else if (controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ResumeScope.maybeOf(context);
    final resumes = controller?.resumes ?? [];
    final isLoading = controller?.isLoading ?? false;
    final isUploading = controller?.isUploading ?? false;
    final isUpdating = controller?.isUpdating ?? false;
    final isDeleting = controller?.isDeleting ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'RESUME MANAGEMENT',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
            ),
            const Spacer(),
            if (controller != null && !isUploading)
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.primary),
                tooltip: 'Upload Resume',
                onPressed: () => _pickAndUpload(context, controller),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (isUploading || isUpdating || isDeleting)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        if (isLoading && resumes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (resumes.isEmpty)
          AppSurface(
            shadows: const [],
            child: Column(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 40,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  'No resumes uploaded yet.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload a PDF or DOCX file to get started.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Upload Resume',
                  leading: const Icon(Icons.upload_file),
                  onPressed: controller != null
                      ? () => _pickAndUpload(context, controller)
                      : null,
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              for (final resume in resumes) ...[
                AppSurface(
                  shadows: const [],
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    resume.filename,
                                    style: Theme.of(context).textTheme.titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (resume.isPrimary) ...[
                                  const SizedBox(width: 8),
                                  const TagChip(label: 'PRIMARY'),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              resume.fileUrl != null
                                  ? 'Uploaded ${resume.createdAt.toString().split(' ').first}'
                                  : 'Uploaded resume',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (controller == null) return;
                          switch (value) {
                            case 'primary':
                              _setPrimary(context, controller, resume);
                              break;
                            case 'extract':
                              _extract(context, controller, resume);
                              break;
                            case 'replace':
                              _pickAndUpdate(context, controller, resume.id);
                              break;
                            case 'download':
                              _download(context, controller, resume);
                              break;
                            case 'delete':
                              _confirmAndDelete(context, controller, resume);
                              break;
                          }
                        },
                        itemBuilder: (ctx) => [
                          if (!resume.isPrimary)
                            const PopupMenuItem(
                              value: 'primary',
                              child: Row(
                                children: [
                                  Icon(Icons.star_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text('Set as Primary'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'extract',
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome, size: 20),
                                SizedBox(width: 8),
                                Text('Re-extract Text'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'replace',
                            child: Row(
                              children: [
                                Icon(Icons.refresh, size: 20),
                                SizedBox(width: 8),
                                Text('Replace File'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'download',
                            child: Row(
                              children: [
                                Icon(Icons.download, size: 20),
                                SizedBox(width: 8),
                                Text('Download File'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: const BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: AppRadii.pill,
    ),
    child: Text(
      'DEVELOPER',
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
    ),
  );
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.name,
    required this.detail,
    required this.selected,
    required this.onTap,
    this.premium = false,
  });
  final String name, detail;
  final bool selected, premium;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: AppRadii.medium,
    child: AppSurface(
      borderColor: selected ? AppColors.primary : AppColors.border,
      color: selected ? AppColors.primarySoft : AppColors.surface,
      shadows: const [],
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(detail, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (premium)
            const Text(
              'PREMIUM ACTIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    ),
  );
}
