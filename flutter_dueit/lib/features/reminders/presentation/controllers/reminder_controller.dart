import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../data/repositories/reminder_repository_impl.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepositoryImpl();
});

class ReminderState {
  final List<NotificationEntity> notifications;
  final bool isLoading;
  final String? error;

  const ReminderState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.read).length;

  ReminderState copyWith({
    List<NotificationEntity>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return ReminderState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReminderController extends StateNotifier<ReminderState> {
  final ReminderRepository _repository;

  ReminderController(this._repository) : super(const ReminderState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repository.getNotifications();
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    await loadNotifications();
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    await loadNotifications();
  }

  Future<void> deleteNotification(String id) async {
    await _repository.deleteNotification(id);
    await loadNotifications();
  }
}

final reminderControllerProvider =
    StateNotifierProvider<ReminderController, ReminderState>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return ReminderController(repo);
});
