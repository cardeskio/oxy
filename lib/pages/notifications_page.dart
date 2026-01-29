import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/models/notification.dart';
import 'package:oxy/services/notification_service.dart';
import 'package:oxy/components/loading_indicator.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/utils/icons.dart';

class NotificationsPage extends StatelessWidget {
  final bool isTenantView;
  final bool isProviderView;

  const NotificationsPage({
    super.key,
    this.isTenantView = false,
    this.isProviderView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, _) {
        if (notificationService.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.lightBackground,
            appBar: AppBar(
              backgroundColor: AppColors.primaryTeal,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              title: const Text('Notifications', style: TextStyle(color: Colors.white)),
            ),
            body: const OxyLoadingOverlay(message: 'Loading notifications...'),
          );
        }

        final notifications = notificationService.notifications;
        final unreadCount = notificationService.unreadCount;

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryTeal,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: Row(
              children: [
                const Text('Notifications', style: TextStyle(color: Colors.white)),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (notifications.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) async {
                    if (value == 'mark_all_read') {
                      await notificationService.markAllAsRead();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All notifications marked as read')),
                        );
                      }
                    } else if (value == 'clear_all') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear All Notifications'),
                          content: const Text('Are you sure you want to delete all notifications?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await notificationService.clearAllNotifications();
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'mark_all_read',
                      child: Row(
                        children: [
                          Icon(Icons.done_all, size: 20),
                          SizedBox(width: 12),
                          Text('Mark all as read'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, size: 20),
                          SizedBox(width: 12),
                          Text('Clear all'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => notificationService.refresh(),
            child: notifications.isEmpty
                ? _buildEmptyState(context)
                : _buildNotificationsList(context, notifications, notificationService),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: AppIcons.notification,
                color: Colors.grey.shade300,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                'No Notifications',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re all caught up!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    List<AppNotification> notifications,
    NotificationService service,
  ) {
    // Group notifications by date
    final grouped = <String, List<AppNotification>>{};
    for (final notification in notifications) {
      final key = _getDateKey(notification.createdAt);
      grouped.putIfAbsent(key, () => []).add(notification);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dateNotifications = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                dateKey,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.lightOnSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...dateNotifications.map((notification) => _NotificationCard(
              notification: notification,
              onTap: () => _handleNotificationTap(context, notification, service),
              onDismiss: () => service.deleteNotification(notification.id),
            )),
          ],
        );
      },
    );
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(notificationDate).inDays < 7) {
      return Formatters.dayOfWeek(date);
    } else {
      return Formatters.shortDate(date);
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    AppNotification notification,
    NotificationService service,
  ) {
    // Mark as read
    if (!notification.isRead) {
      service.markAsRead(notification.id);
    }

    // Navigate to relevant page using go() to avoid shell navigator conflicts
    final route = notification.navigationRoute;
    if (route != null) {
      context.go(route);
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead 
                ? Colors.white 
                : AppColors.primaryTeal.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: notification.isRead
                ? null
                : Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.2),
                    width: 1,
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getIconColor(notification.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: _getIcon(notification.type),
                    color: _getIconColor(notification.type),
                    size: 22,
                  ),
                ),
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
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.body != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.lightOnSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      Formatters.relativeDate(notification.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newTicket:
      case NotificationType.ticketMessage:
      case NotificationType.ticketUpdated:
      case NotificationType.ticketReply:
        return AppIcons.maintenance;
      case NotificationType.newEnquiry:
      case NotificationType.enquiryMessage:
      case NotificationType.enquiryUpdated:
      case NotificationType.enquiryReply:
        return HugeIcons.strokeRoundedMail01;
      case NotificationType.paymentReceived:
        return AppIcons.payments;
      case NotificationType.invoiceCreated:
        return AppIcons.invoices;
      case NotificationType.leaseExpiring:
      case NotificationType.leaseReminder:
        return HugeIcons.strokeRoundedCalendar03;
      case NotificationType.orderNew:
        return HugeIcons.strokeRoundedShoppingCart01;
      case NotificationType.orderUpdate:
        return HugeIcons.strokeRoundedDeliveryBox01;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.newTicket:
      case NotificationType.ticketMessage:
        return AppColors.warning;
      case NotificationType.ticketUpdated:
      case NotificationType.ticketReply:
        return AppColors.info;
      case NotificationType.newEnquiry:
      case NotificationType.enquiryMessage:
      case NotificationType.enquiryUpdated:
      case NotificationType.enquiryReply:
        return AppColors.primaryTeal;
      case NotificationType.paymentReceived:
        return AppColors.success;
      case NotificationType.invoiceCreated:
        return AppColors.warning;
      case NotificationType.leaseExpiring:
      case NotificationType.leaseReminder:
        return AppColors.error;
      case NotificationType.orderNew:
        return AppColors.success;
      case NotificationType.orderUpdate:
        return AppColors.info;
    }
  }
}
