import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/notifications/cubit/notification_state.dart';
import 'package:root2route/features/notifications/data/models/notification_model.dart';
import 'package:root2route/features/notifications/data/services/notification_service.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationService _notificationService = NotificationService();

  NotificationCubit() : super(NotificationInitial());

  Future<void> fetchNotifications() async {
    try {
      emit(NotificationLoading());
      final results = await Future.wait([
        _notificationService.getNotifications(),
        _notificationService.getUnreadCount(),
      ]);

      final notifications = results[0] as List<NotificationModel>;
      final unreadCount = results[1] as int;

      emit(NotificationLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> markAsRead(String id) async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      // Optimistic update locally
      final updatedNotifications = currentState.notifications.map((n) {
        if (n.id == id && !n.isRead) {
          n.isRead = true;
        }
        return n;
      }).toList();

      final newUnreadCount = (currentState.unreadCount > 0) ? currentState.unreadCount - 1 : 0;

      emit(NotificationLoaded(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      ));

      // Call API
      await _notificationService.markAsRead(id);
    }
  }

  Future<void> markAllAsRead() async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      // Optimistic update locally
      final updatedNotifications = currentState.notifications.map((n) {
        n.isRead = true;
        return n;
      }).toList();

      emit(NotificationLoaded(
        notifications: updatedNotifications,
        unreadCount: 0,
      ));

      // Call API
      await _notificationService.markAllAsRead();
    }
  }
}
