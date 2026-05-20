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
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> markAsRead(String id) async {
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
    emit(state.copyWith(notifications: updatedNotifications));

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
    emit(state.copyWith(notifications: updatedNotifications));

    final success = await repository.markAllAsRead();
    if (!success) {
      fetchNotifications();
    }
  }

  Future<void> deleteNotification(String id) async {
    // Optimistic UI update
    final updatedNotifications = state.notifications.where((n) => n.id != id).toList();
    emit(state.copyWith(notifications: updatedNotifications));

    final success = await repository.deleteNotification(id);
    if (!success) {
      fetchNotifications();
    }
  }
}
