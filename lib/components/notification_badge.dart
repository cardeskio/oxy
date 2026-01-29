import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:oxy/services/notification_service.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/utils/icons.dart';

/// Notification bell icon with badge showing unread count
class NotificationBadge extends StatelessWidget {
  final Color? iconColor;
  final double size;
  final bool isTenantView;
  final bool isProviderView;

  const NotificationBadge({
    super.key,
    this.iconColor,
    this.size = 24,
    this.isTenantView = false,
    this.isProviderView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, _) {
        final unreadCount = notificationService.unreadCount;

        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              HugeIcon(
                icon: AppIcons.notification,
                color: iconColor ?? Colors.white,
                size: size,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: iconColor != null 
                            ? Theme.of(context).scaffoldBackgroundColor
                            : AppColors.primaryTeal,
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            final route = isTenantView 
                ? '/tenant/notifications' 
                : isProviderView 
                    ? '/provider/notifications'
                    : '/notifications';
            context.push(route);
          },
          tooltip: 'Notifications${unreadCount > 0 ? ' ($unreadCount unread)' : ''}',
        );
      },
    );
  }
}

/// Compact notification indicator (just a dot)
class NotificationDot extends StatelessWidget {
  const NotificationDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, _) {
        if (!notificationService.hasUnread) {
          return const SizedBox.shrink();
        }

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
