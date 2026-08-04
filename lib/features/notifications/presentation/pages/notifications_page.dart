import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/shimmer/shimmer_widgets.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationsBloc>(
      create: (_) =>
          getIt<NotificationsBloc>()..add(const NotificationsStarted()),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Tell HomeBloc the user opened notifications — resets the red dot
    // and fires markAllRead on the server via the existing event handler.
    getIt<HomeBloc>().add(const HomeNotificationsOpened());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      context
          .read<NotificationsBloc>()
          .add(const NotificationsLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.transparent,
      body: Stack(
        children: <Widget>[
          const AppScreenBackground(),
          SafeArea(
            child: Padding(
              padding:
                  AppSize.insets(context, left: 16, right: 16, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  BlocBuilder<NotificationsBloc, NotificationsState>(
                    buildWhen: (p, c) =>
                        p.unreadCount != c.unreadCount ||
                        p.notifications.isEmpty != c.notifications.isEmpty,
                    builder: (context, state) {
                      return Row(
                        children: <Widget>[
                          Expanded(
                            child: AppBackHeader(
                              title: 'Alerts',
                              onBack: () => context.pop(),
                            ),
                          ),
                          if (state.notifications.isNotEmpty &&
                              state.unreadCount > 0)
                            TextButton(
                              onPressed: () => context
                                  .read<NotificationsBloc>()
                                  .add(
                                    const NotificationsMarkAllReadRequested(),
                                  ),
                              child: Text(
                                'Mark all read',
                                style: TextStyleConstants.bodyMedium.copyWith(
                                  color: ColorConstants.brandBlue,
                                  fontSize: AppSize.sp(context, 12),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: AppSize.h(context, 16)),
                  Expanded(
                    child: BlocBuilder<NotificationsBloc, NotificationsState>(
                      builder: (context, state) {
                        if (state.isLoading) {
                          return ShimmerNotificationList(count: 6);
                        }

                        if (state.status == NotificationsStatus.failure) {
                          return _ErrorState(
                            message: state.errorMessage ??
                                'Could not load notifications.',
                            onRetry: () => context
                                .read<NotificationsBloc>()
                                .add(const NotificationsRefreshed()),
                          );
                        }

                        if (state.notifications.isEmpty) {
                          return _EmptyState();
                        }

                        return RefreshIndicator(
                          color: ColorConstants.brandBlue,
                          onRefresh: () async {
                            final bloc =
                                context.read<NotificationsBloc>();
                            bloc.add(const NotificationsRefreshed());
                            await bloc.stream.firstWhere(
                              (s) => !s.isRefreshing,
                            );
                          },
                          child: ListView.separated(
                            controller: _scrollController,
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(
                              bottom: AppSize.h(context, 24),
                            ),
                            itemCount: state.notifications.length +
                                (state.isLoadingMore ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                SizedBox(height: AppSize.h(context, 10)),
                            itemBuilder: (_, index) {
                              if (index == state.notifications.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                );
                              }
                              final notif = state.notifications[index];
                              return _NotificationCard(
                                notification: notif,
                                onTap: notif.read
                                    ? null
                                    : () => context
                                        .read<NotificationsBloc>()
                                        .add(
                                          NotificationsMarkReadRequested(
                                            notif.notificationId,
                                          ),
                                        ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notification card ───────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    this.onTap,
  });

  final AppNotification notification;
  final VoidCallback? onTap;

  _NotifStyle get _style => _styleFor(notification.type);

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.read;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: AppSize.insets(
          context,
          left: 14,
          right: 14,
          top: 14,
          bottom: 14,
        ),
        decoration: BoxDecoration(
          color: isUnread
              ? ColorConstants.brandBlue.withValues(alpha: 0.04)
              : ColorConstants.white,
          borderRadius:
              BorderRadius.circular(AppSize.r(context, 14)),
          border: Border.all(
            color: isUnread
                ? ColorConstants.brandBlue.withValues(alpha: 0.22)
                : ColorConstants.line,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // icon bubble
            Container(
              width: AppSize.r(context, 40),
              height: AppSize.r(context, 40),
              decoration: BoxDecoration(
                color: _style.color.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(AppSize.r(context, 12)),
              ),
              child: Icon(
                _style.icon,
                color: _style.color,
                size: AppSize.r(context, 20),
              ),
            ),
            SizedBox(width: AppSize.w(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyleConstants.bodyMedium.copyWith(
                            fontSize: AppSize.sp(context, 14),
                            fontWeight: FontWeight.w700,
                            color: ColorConstants.ink,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          margin: EdgeInsets.only(
                            left: AppSize.w(context, 6),
                            top: AppSize.h(context, 4),
                          ),
                          width: AppSize.r(context, 8),
                          height: AppSize.r(context, 8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorConstants.brandBlue,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: AppSize.h(context, 4)),
                  Text(
                    notification.message,
                    style: TextStyleConstants.caption.copyWith(
                      fontSize: AppSize.sp(context, 12.5),
                      color: ColorConstants.mute,
                    ),
                  ),
                  SizedBox(height: AppSize.h(context, 6)),
                  Text(
                    _timeLabel(notification.createdAt),
                    style: TextStyleConstants.caption.copyWith(
                      fontSize: AppSize.sp(context, 11),
                      color: ColorConstants.soft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('dd MMM').format(dt);
  }
}

// ─── Style mapping ────────────────────────────────────────────────────────────

class _NotifStyle {
  const _NotifStyle({required this.icon, required this.color});
  final IconData icon;
  final Color color;
}

_NotifStyle _styleFor(AppNotificationType type) {
  switch (type) {
    case AppNotificationType.tradeCreated:
      return const _NotifStyle(
        icon: Icons.bolt_rounded,
        color: ColorConstants.brandBlue,
      );
    case AppNotificationType.tradeClosed:
      return const _NotifStyle(
        icon: Icons.flag_rounded,
        color: ColorConstants.green,
      );
    case AppNotificationType.tradeModified:
      return const _NotifStyle(
        icon: Icons.edit_rounded,
        color: ColorConstants.amber,
      );
    case AppNotificationType.adminBroadcast:
      return const _NotifStyle(
        icon: Icons.campaign_rounded,
        color: ColorConstants.brandBlue,
      );
    case AppNotificationType.other:
      return const _NotifStyle(
        icon: Icons.notifications_rounded,
        color: ColorConstants.mute,
      );
  }
}

// ─── Empty / error states ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.notifications_off_outlined,
            size: AppSize.r(context, 48),
            color: ColorConstants.line,
          ),
          SizedBox(height: AppSize.h(context, 14)),
          Text(
            'No notifications yet',
            style: TextStyleConstants.bodyMedium.copyWith(
              color: ColorConstants.mute,
              fontSize: AppSize.sp(context, 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSize.symmetric(context, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyleConstants.bodyMedium.copyWith(
                color: ColorConstants.mute,
                fontSize: AppSize.sp(context, 13),
              ),
            ),
            SizedBox(height: AppSize.h(context, 16)),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.brandBlue,
                foregroundColor: ColorConstants.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSize.r(context, 12)),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
