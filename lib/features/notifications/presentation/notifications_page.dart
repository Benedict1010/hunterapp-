import 'package:flutter/material.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_surface.dart';
import '../data/mock_notifications.dart';
import '../domain/app_notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late List<AppNotification> _notifications;
  var _unreadOnly = false;
  @override
  void initState() {
    super.initState();
    _notifications = mockNotifications;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _notifications
        .where((item) => !_unreadOnly || !item.isRead)
        .toList();
    return AppShell(
      navigationVariant: AppNavigationVariant.optimize,
      selectedIndex: 2,
      showNotificationAction: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              IconButton(
                onPressed: () => _message(
                  'Filters are not available in this local preview.',
                ),
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter',
              ),
              IconButton(
                onPressed: _markAllRead,
                icon: const Icon(Icons.done_all),
                tooltip: 'Mark all as read',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'CAREER ASSISTANT UPDATES',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _FilterTab(
                label: 'All Alerts',
                selected: !_unreadOnly,
                onTap: () => setState(() => _unreadOnly = false),
              ),
              const SizedBox(width: 18),
              _FilterTab(
                label: 'Unread',
                selected: _unreadOnly,
                hasDot: _notifications.any((item) => !item.isRead),
                onTap: () => setState(() => _unreadOnly = true),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final notification in visible)
            _NotificationCard(
              notification: notification,
              onRead: () => _read(notification.id),
              onAction: () => _open(notification),
            ),
          const SizedBox(height: 8),
          AppSurface(
            color: AppColors.primarySoft,
            borderColor: Colors.transparent,
            shadows: const [],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Pro Tip',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Text(
                        'Applications with a tailored resume are more likely to receive a response.',
                      ),
                      TextButton(
                        onPressed: () => _message(
                          'Tips are available in this local preview.',
                        ),
                        child: const Text('Learn more  ›'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'You are all caught up for the last 7 days.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _read(String id) => setState(
    () => _notifications = [
      for (final item in _notifications)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ],
  );
  void _markAllRead() {
    setState(
      () => _notifications = [
        for (final item in _notifications) item.copyWith(isRead: true),
      ],
    );
    _message('All notifications marked as read.');
  }

  void _open(AppNotification notification) {
    _read(notification.id);
    if (notification.type == NotificationType.application) {
      Navigator.of(context).pushNamed(AppRoutes.applicationDetails);
    } else {
      _message(
        '${notification.actionLabel ?? 'This action'} is not available in this local preview.',
      );
    }
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.hasDot = false,
  });
  final String label;
  final bool selected, hasDot;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          if (hasDot)
            const Padding(
              padding: EdgeInsets.only(left: 5),
              child: CircleAvatar(
                radius: 3,
                backgroundColor: AppColors.primary,
              ),
            ),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: SizedBox(width: 0),
            ),
        ],
      ),
    ),
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onRead,
    required this.onAction,
  });
  final AppNotification notification;
  final VoidCallback onRead, onAction;
  @override
  Widget build(BuildContext context) {
    final icon = switch (notification.type) {
      NotificationType.match => Icons.auto_awesome,
      NotificationType.resume => Icons.description_outlined,
      NotificationType.application => Icons.visibility_outlined,
      NotificationType.opportunity => Icons.work_outline,
      NotificationType.insight => Icons.insights_outlined,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppSurface(
        color: notification.isRead ? AppColors.surface : AppColors.primarySoft,
        borderColor: notification.isRead
            ? AppColors.border
            : AppColors.primary.withValues(alpha: .2),
        shadows: const [],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadii.small,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (!notification.isRead)
                        const CircleAvatar(
                          radius: 4,
                          backgroundColor: AppColors.primary,
                        ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onRead,
                        icon: const Icon(Icons.more_horiz),
                        tooltip: 'Mark as read',
                      ),
                    ],
                  ),
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.time,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      if (notification.actionLabel != null)
                        TextButton(
                          onPressed: onAction,
                          child: Text(notification.actionLabel!),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
