import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:green_rabbit/features/market/presentation/pages/instrument_detail_page.dart';
import 'package:green_rabbit/features/alerts/presentation/cubit/alert_cubit.dart';
import '../../data/models/notification_model.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationCubit>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
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
              if (state.notifications.any((n) => !n.isRead))
                TextButton(
                  onPressed: () {
                    context.read<NotificationCubit>().markAllAsRead();
                  },
                  child: const Text('Mark all as read', style: TextStyle(color: Color(0xFF4C3BC9), fontSize: 13)),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: state.isLoading && state.notifications.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => context.read<NotificationCubit>().fetchNotifications(),
                  child: state.notifications.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: state.notifications.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final notification = state.notifications[index];
                            return Dismissible(
                              key: Key(notification.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              ),
                              onDismissed: (_) {
                                context.read<NotificationCubit>().deleteNotification(notification.id);
                              },
                              child: _buildNotificationCard(context, notification),
                            );
                          },
                        ),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off_outlined, size: 64, color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12),
              const SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : Colors.black38, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notification) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        context.read<NotificationCubit>().markAsRead(notification.id);
        
        final instrumentId = notification.data.instrumentId;
        if (instrumentId != null && instrumentId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InstrumentDetailPage(instrumentId: instrumentId),
            ),
          );
        }
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
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(color: Color(0xFF4C3BC9), shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _sanitizeBody(notification),
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

  String _sanitizeBody(NotificationModel notification) {
    final String body = notification.body;
    
    // Check if the body contains the JavaScript interpolation template bug
    if (body.contains('Number(price)') || body.contains('{Number(') || body.contains('Number(target)')) {
      double? triggeredPrice;
      double? targetPrice;
      
      // 1. Try to find the values from the metadata extra fields
      final metadataExtra = notification.data.extraFields;
      triggeredPrice = _parsePrice(metadataExtra['triggeredPrice'] ?? metadataExtra['price'] ?? metadataExtra['currentPrice']);
      targetPrice = _parsePrice(metadataExtra['targetPrice'] ?? metadataExtra['target']);
      
      // 2. Fallback: If not found in extraFields, try to find in AlertCubit matching alert
      if (targetPrice == null && notification.data.alertId != null) {
        try {
          final alerts = context.read<AlertCubit>().state.alerts;
          final alert = alerts.firstWhere((a) => a.id == notification.data.alertId);
          targetPrice = alert.targetPrice;
          triggeredPrice = alert.triggeredPrice;
        } catch (_) {}
      }

      // 3. String replacement of patterns like "$$ {Number(price).toFixed(2)}" or "$${Number(price).toFixed(2)}"
      if (triggeredPrice != null || targetPrice != null) {
        final regex = RegExp(r'\$?\$\s*\{Number\([^)]+\)\.toFixed\(\d+\)\}');
        String result = body;
        
        // First match is triggeredPrice/price (if available)
        if (regex.hasMatch(result)) {
          final val = triggeredPrice ?? targetPrice ?? 0.0;
          result = result.replaceFirst(regex, '\$${val.toStringAsFixed(2)}');
        }
        // Second match is targetPrice (if available)
        if (regex.hasMatch(result)) {
          final val = targetPrice ?? triggeredPrice ?? 0.0;
          result = result.replaceFirst(regex, '\$${val.toStringAsFixed(2)}');
        }
        return result;
      } else {
        // Ultimate fallback: Clean it up gracefully to show a user-friendly string
        final symbol = notification.data.instrumentSymbol ?? 'Asset';
        return '$symbol reached your target price.';
      }
    }
    
    return body;
  }

  double? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
