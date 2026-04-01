import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/tab_navigation_service.dart';

void showNotificationPanel(BuildContext context, NotificationService service) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NotificationPanel(service: service),
  );
}

class _NotificationPanel extends StatelessWidget {
  final NotificationService service;
  const _NotificationPanel({required this.service});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Notifications',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (service.unreadCount > 0)
                    TextButton(
                      onPressed: () async {
                        await service.markAllRead();
                      },
                      child: const Text('Mark all read',
                          style: TextStyle(color: Color(0xFFE53935), fontSize: 13)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // List
            Expanded(
              child: ListenableBuilder(
                listenable: service,
                builder: (_, __) {
                  if (service.notifications.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_outlined,
                              size: 56, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No notifications yet',
                              style: TextStyle(color: Colors.grey, fontSize: 15)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: controller,
                    itemCount: service.notifications.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (ctx, i) {
                      final n = service.notifications[i];
                      return _NotificationTile(
                        notification: n,
                        onTap: () async {
                          await service.markRead(n.id);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            _handleNavigation(ctx, n.actionUrl);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, String actionUrl) {
    final nav = TabNavigationService();
    if (actionUrl.contains('/workout')) {
      nav.goToWorkout();
    } else if (actionUrl.contains('/nutrition')) {
      nav.goToNutrition();
    } else if (actionUrl.contains('/challenge')) {
      nav.goToCommunity();
    } else if (actionUrl.contains('/community')) {
      nav.goToCommunity();
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isRead ? Colors.white : const Color(0xFFFFF3E0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notification.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(notification.icon, color: notification.color, size: 22),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.timeAgo,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
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
