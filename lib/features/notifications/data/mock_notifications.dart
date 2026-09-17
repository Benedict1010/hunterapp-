import '../domain/app_notification.dart';

const mockNotifications = [
  AppNotification(
    id: 'match',
    type: NotificationType.match,
    title: 'High Match Found!',
    message:
        'Senior Frontend Engineer at TechFlow Systems is a 96% match for you.',
    time: '12 min ago',
    isRead: false,
    actionLabel: 'View job',
  ),
  AppNotification(
    id: 'resume',
    type: NotificationType.resume,
    title: 'Resume Optimized',
    message: 'Your tailored resume is ready for Software Engineer roles.',
    time: '1 hr ago',
    isRead: false,
    actionLabel: 'Review resume',
  ),
  AppNotification(
    id: 'viewed',
    type: NotificationType.application,
    title: 'Application Viewed',
    message: 'ABC Technologies viewed your application.',
    time: 'Yesterday',
    isRead: true,
    actionLabel: 'View application',
  ),
  AppNotification(
    id: 'opportunity',
    type: NotificationType.opportunity,
    title: 'New Opportunity',
    message: 'A remote Product Designer role was added to your matches.',
    time: 'Yesterday',
    isRead: true,
    actionLabel: 'Explore match',
  ),
  AppNotification(
    id: 'insights',
    type: NotificationType.insight,
    title: 'Weekly Insights Ready',
    message: 'See how your search activity performed this week.',
    time: '3 days ago',
    isRead: true,
    actionLabel: 'View insights',
  ),
];
