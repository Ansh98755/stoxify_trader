import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc
    extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({required NotificationsRepository repository})
      : _repository = repository,
        super(const NotificationsState()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationsRefreshed>(_onRefreshed);
    on<NotificationsLoadMoreRequested>(_onLoadMore);
    on<NotificationsMarkReadRequested>(_onMarkRead);
    on<NotificationsMarkAllReadRequested>(_onMarkAllRead);
  }

  final NotificationsRepository _repository;

  Future<void> _onStarted(
    NotificationsStarted event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.status == NotificationsStatus.success) return;
    emit(state.copyWith(
      status: NotificationsStatus.loading,
      clearError: true,
    ));
    await _loadPage(1, emit, replace: true);
  }

  Future<void> _onRefreshed(
    NotificationsRefreshed event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, clearError: true));
    await _loadPage(1, emit, replace: true);
  }

  Future<void> _onLoadMore(
    NotificationsLoadMoreRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    await _loadPage(state.page + 1, emit, replace: false);
  }

  Future<void> _loadPage(
    int page,
    Emitter<NotificationsState> emit, {
    required bool replace,
  }) async {
    try {
      final result =
          await _repository.fetchNotifications(page: page);
      final merged = replace
          ? result.notifications
          : <AppNotification>[...state.notifications, ...result.notifications];
      emit(state.copyWith(
        status: NotificationsStatus.success,
        notifications: merged,
        page: result.page,
        hasMore: result.hasMore,
        isLoadingMore: false,
        isRefreshing: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: state.notifications.isEmpty
            ? NotificationsStatus.failure
            : NotificationsStatus.success,
        isLoadingMore: false,
        isRefreshing: false,
        errorMessage: _message(e),
      ));
    }
  }

  Future<void> _onMarkRead(
    NotificationsMarkReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    // Optimistic update — flip read flag immediately.
    final updated = state.notifications.map((n) {
      if (n.notificationId == event.notificationId) {
        return n.copyWith(read: true, readAt: DateTime.now());
      }
      return n;
    }).toList();
    emit(state.copyWith(notifications: updated));

    try {
      final fresh = await _repository.markRead(event.notificationId);
      final synced = state.notifications.map((n) {
        return n.notificationId == event.notificationId ? fresh : n;
      }).toList();
      emit(state.copyWith(notifications: synced));
    } catch (_) {
      // Rollback on failure.
      final rolledBack = state.notifications.map((n) {
        if (n.notificationId == event.notificationId) {
          return n.copyWith(read: false, readAt: null);
        }
        return n;
      }).toList();
      emit(state.copyWith(notifications: rolledBack));
    }
  }

  Future<void> _onMarkAllRead(
    NotificationsMarkAllReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    // Optimistic update — mark all read instantly.
    final updated = state.notifications
        .map((n) => n.copyWith(read: true, readAt: DateTime.now()))
        .toList();
    emit(state.copyWith(notifications: updated));

    try {
      await _repository.markAllRead();
    } catch (_) {
      // Rollback.
      emit(state.copyWith(notifications: state.notifications));
    }
  }

  String _message(Object e) {
    return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}
