import 'package:flutter/material.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import '../../data/models/notification_model.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for display based on API docs
    final notifications = [
      NotificationModel(
        id: 'a1b2c3d4-e5f6-7890-abcd-ef0123456789',
        type: 'price_alert',
        title: 'AAPL Price Alert',
        body: 'AAPL reached 250.50 — above your 200.00 target',
        data: NotificationMetadata(
          alertId: 'b2c3d4e5-f6a7-8901-bcde-f01234567890',
          instrumentId: 'inst_001',
          instrumentSymbol: 'AAPL',
          type: 'price_alert',
          deepLink: '/instruments/inst_001',
        ),
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'b2c3d4e5-f6a7-8901-bcde-f01234567890',
        type: 'news',
        title: 'Market Update',
        body: 'NVIDIA quarterly earnings report is out. See analysis.',
        data: NotificationMetadata(),
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // API: Mark all as read
            },
            child: const Text('Mark all as read', style: TextStyle(color: Color(0xFF4C3BC9), fontSize: 13)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(context, notification);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notification) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        // API: Mark as read
        // Handle deep link
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? (notification.isRead ? AppColors.surface.withOpacity(0.5) : AppColors.surface) : (notification.isRead ? Colors.grey.shade50 : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIconColor(notification.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIcon(notification.type), color: _getIconColor(notification.type), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Color(0xFF4C3BC9), shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'price_alert': return Icons.trending_up;
      case 'news': return Icons.article_outlined;
      case 'ai_insight': return Icons.auto_awesome_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'price_alert': return const Color(0xFF4C3BC9);
      case 'news': return Colors.blue;
      case 'ai_insight': return Colors.amber;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
