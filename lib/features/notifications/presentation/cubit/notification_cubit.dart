import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/models/notification_model.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository repository;

  NotificationCubit({required this.repository}) : super(const NotificationState());

  Future<void> fetchNotifications() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final notifications = await repository.fetchNotifications();
      // Sort notifications by date descending
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(state.copyWith(isLoading: false, notifications: notifications));
      await fetchUnreadCount();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final count = await repository.fetchUnreadCount();
      emit(state.copyWith(unreadCount: count));
    } catch (e) {
      // Ignore count fetch errors
    }
  }

  Future<void> registerFcmToken({
    required String fcmToken,
    required String deviceType,
    required String deviceId,
  }) async {
    try {
      await repository.registerDeviceToken(
        fcmToken: fcmToken,
        deviceType: deviceType,
        deviceId: deviceId,
      );
    } catch (e) {
      // Ignore FCM registration errors
    }
  }

  Future<void> markAsRead(String id) async {
    // Determine if the notification was unread
    final wasUnread = state.notifications.any((n) => n.id == id && !n.isRead);

    // Optimistic UI update
    final updatedNotifications = state.notifications.map((n) {
      if (n.id == id) {
        return NotificationModel(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          data: n.data,
          isRead: true,
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();
    
    emit(state.copyWith(
      notifications: updatedNotifications,
      unreadCount: wasUnread ? (state.unreadCount > 0 ? state.unreadCount - 1 : 0) : state.unreadCount,
    ));

    final success = await repository.markAsRead(id);
    if (!success) {
      // Revert if failed
      fetchNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    // Optimistic UI update
    final updatedNotifications = state.notifications.map((n) {
      return NotificationModel(
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        data: n.data,
        isRead: true,
        createdAt: n.createdAt,
      );
    }).toList();
    
    emit(state.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
    ));

    final success = await repository.markAllAsRead();
    if (!success) {
      fetchNotifications();
    }
  }

  Future<void> deleteNotification(String id) async {
    final wasUnread = state.notifications.any((n) => n.id == id && !n.isRead);

    // Optimistic UI update
    final updatedNotifications = state.notifications.where((n) => n.id != id).toList();
    emit(state.copyWith(
      notifications: updatedNotifications,
      unreadCount: wasUnread ? (state.unreadCount > 0 ? state.unreadCount - 1 : 0) : state.unreadCount,
    ));

    final success = await repository.deleteNotification(id);
    if (!success) {
      fetchNotifications();
    }
  }
}
