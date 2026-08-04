import 'package:equatable/equatable.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class NotificationsStarted extends NotificationsEvent {
  const NotificationsStarted();
}

final class NotificationsRefreshed extends NotificationsEvent {
  const NotificationsRefreshed();
}

final class NotificationsLoadMoreRequested extends NotificationsEvent {
  const NotificationsLoadMoreRequested();
}

final class NotificationsMarkReadRequested extends NotificationsEvent {
  const NotificationsMarkReadRequested(this.notificationId);

  final String notificationId;

  @override
  List<Object?> get props => <Object?>[notificationId];
}

final class NotificationsMarkAllReadRequested extends NotificationsEvent {
  const NotificationsMarkAllReadRequested();
}
