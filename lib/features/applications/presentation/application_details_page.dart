import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/application_scope.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';

import '../../../core/widgets/app_chips.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../domain/job_application.dart';
import 'application_controller.dart';

class ApplicationDetailsPage extends StatefulWidget {
  const ApplicationDetailsPage({super.key});

  @override
  State<ApplicationDetailsPage> createState() => _ApplicationDetailsPageState();
}

class _ApplicationDetailsPageState extends State<ApplicationDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDetail();
    });
  }

  void _initDetail() {
    final appId = ModalRoute.of(context)?.settings.arguments as String?;
    final controller = ApplicationScope.maybeOf(context);
    if (controller == null) return;

    if (appId != null && appId.isNotEmpty) {
      controller.loadApplicationDetail(appId);
    }
  }

  void _showStatusDialog(
    BuildContext context,
    Application app,
    ApplicationController controller,
  ) {
    var selected = app.status;
    final noteController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Update Application Status'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select New Status:'),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ApplicationStatus.values.map((st) {
                        final isSel = selected == st;
                        return ChoiceChip(
                          label: Text(st.label),
                          selected: isSel,
                          onSelected: (_) {
                            setDialogState(() {
                              selected = st;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Optional Note / Update Reason',
                        hintText: 'e.g. Completed technical round',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    if (noteController.text.trim().isNotEmpty) {
                      await controller.addTimelineNote(
                        app.id,
                        selected,
                        note: noteController.text.trim(),
                      );
                    } else {
                      await controller.updateApplicationStatus(
                        app.id,
                        selected,
                      );
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Status updated successfully.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ApplicationScope.maybeOf(context);
    final app = controller?.selectedApplication;
    final timeline = controller?.timelineEvents ?? [];

    return AppShell(
      navigationVariant: AppNavigationVariant.optimize,
      selectedIndex: 1,
      showNotificationAction: false,
      child: Builder(
        builder: (context) {
          if (controller != null && controller.isLoadingDetail) {
            return const Center(child: CircularProgressIndicator());
          }

          if (app == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      controller?.detailErrorMessage ??
                          'Application details not found.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  const TagChip(
                    label: 'Application Details',
                    color: AppColors.primarySoft,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Update Status',
                    onPressed: () =>
                        _showStatusDialog(context, app, controller!),
                    icon: const Icon(Icons.edit_note_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ProcessBanner(status: app.status),
              const SizedBox(height: 16),
              AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: AppRadii.small,
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                app.company,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _showStatusDialog(context, app, controller!),
                          icon: const Icon(Icons.more_horiz),
                          tooltip: 'More options',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TagChip(label: app.status.label),
                        TagChip(label: app.location),
                        TagChip(label: 'Applied ${app.date}'),
                        if (app.source != null && app.source!.isNotEmpty)
                          TagChip(label: 'Source: ${app.source}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'HIRING PROCESS',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        _showStatusDialog(context, app, controller!),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Step'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (timeline.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No timeline events yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                for (var index = 0; index < timeline.length; index++)
                  _TimelineStep(
                    event: timeline[index],
                    isLast: index == timeline.length - 1,
                  ),
              const SizedBox(height: 12),
              if (app.applicationUrl != null && app.applicationUrl!.isNotEmpty)
                AppSurface(
                  color: AppColors.primarySoft,
                  borderColor: Colors.transparent,
                  shadows: const [],
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.open_in_new_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'External Tracking',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              app.applicationUrl!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final url = app.applicationUrl;
                          if (url != null && url.isNotEmpty) {
                            final uri = Uri.tryParse(url.trim());
                            if (uri != null &&
                                (uri.scheme == 'http' ||
                                    uri.scheme == 'https')) {
                              try {
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              } catch (_) {}
                            }
                          }
                        },
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Last updated ${app.date}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProcessBanner extends StatelessWidget {
  const _ProcessBanner({required this.status});
  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final title = switch (status) {
      ApplicationStatus.applied => 'Application submitted',
      ApplicationStatus.viewed => 'Application viewed by recruiter',
      ApplicationStatus.interview => 'You are in the interview stage',
      ApplicationStatus.offer => 'Congratulations! Offer received',
      ApplicationStatus.rejected => 'Application decision: Not selected',
      ApplicationStatus.withdrawn => 'Application withdrawn',
    };

    final progress = switch (status) {
      ApplicationStatus.applied => 0.25,
      ApplicationStatus.viewed => 0.50,
      ApplicationStatus.interview => 0.75,
      ApplicationStatus.offer => 1.00,
      ApplicationStatus.rejected => 1.00,
      ApplicationStatus.withdrawn => 0.00,
    };

    return AppSurface(
      color: AppColors.surfaceSubtle,
      shadows: const [],
      child: Row(
        children: [
          const Icon(
            Icons.account_tree_outlined,
            color: AppColors.primary,
            size: 42,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  borderRadius: AppRadii.pill,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.event, required this.isLast});
  final ApplicationTimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = switch (event.status) {
      ApplicationStatus.applied => AppColors.primary,
      ApplicationStatus.viewed => AppColors.primary,
      ApplicationStatus.interview => AppColors.warning,
      ApplicationStatus.offer => AppColors.success,
      ApplicationStatus.rejected => AppColors.textSecondary,
      ApplicationStatus.withdrawn => AppColors.textSecondary,
    };

    final icon = switch (event.status) {
      ApplicationStatus.applied => Icons.check,
      ApplicationStatus.viewed => Icons.visibility_outlined,
      ApplicationStatus.interview => Icons.calendar_today_outlined,
      ApplicationStatus.offer => Icons.workspace_premium_outlined,
      ApplicationStatus.rejected => Icons.close_rounded,
      ApplicationStatus.withdrawn => Icons.remove_circle_outline,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: color.withValues(alpha: .16),
                  child: Icon(icon, size: 16, color: color),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.date,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
