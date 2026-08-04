import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/shimmer/shimmer_widgets.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_app_notification_bar.dart';
import '../../../../core/widgets/common_trading_card.dart';
import '../../../../core/widgets/web_trade_card_layout.dart';
import '../../../../features/home/domain/repositories/home_repository.dart';
import '../bloc/saved_trades_bloc.dart';
import '../bloc/saved_trades_event.dart';
import '../bloc/saved_trades_state.dart';

class SavedTradesPage extends StatelessWidget {
  const SavedTradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SavedTradesBloc>(
      create: (_) => SavedTradesBloc(
        repository: getIt<HomeRepository>(),
      )..add(const SavedTradesStarted()),
      child: const _SavedTradesView(),
    );
  }
}

class _SavedTradesView extends StatefulWidget {
  const _SavedTradesView();

  @override
  State<_SavedTradesView> createState() => _SavedTradesViewState();
}

class _SavedTradesViewState extends State<_SavedTradesView> {
  bool _flushbarVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: ColorConstants.transparent,
      body: BlocListener<SavedTradesBloc, SavedTradesState>(
        listenWhen: (prev, curr) =>
            prev.removeSuccess != curr.removeSuccess ||
            prev.removeError != curr.removeError,
        listener: (context, state) async {
          if (_flushbarVisible) return;

          if (state.removeSuccess) {
            _flushbarVisible = true;
            await CommonAppNotificationBar.error(
              context: context,
              title: 'Trade removed',
              message: 'Removed from your saved trades.',
            );
            _flushbarVisible = false;
            if (context.mounted) {
              context
                  .read<SavedTradesBloc>()
                  .add(const SavedTradesClearFeedback());
            }
          } else if (state.removeError != null) {
            _flushbarVisible = true;
            await CommonAppNotificationBar.error(
              context: context,
              title: 'Error',
              message: state.removeError!,
            );
            _flushbarVisible = false;
            if (context.mounted) {
              context
                  .read<SavedTradesBloc>()
                  .add(const SavedTradesClearFeedback());
            }
          }
        },
        child: Stack(
          children: <Widget>[
            const AppScreenBackground(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding:
                        AppSize.insets(context, left: 16, right: 16, top: 4),
                    child: AppBackHeader(title: 'Saved trades'),
                  ),
                  SizedBox(height: AppSize.h(context, 8)),
                  Expanded(
                    child: BlocBuilder<SavedTradesBloc, SavedTradesState>(
                      builder: (context, state) {
                        // Loading
                        if (state.isLoading) {
                          if (isDesktopWeb(context)) {
                            return CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: <Widget>[
                                WebTradeCardGridSliver(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 8, 16, 32),
                                  itemCount: 4,
                                  itemBuilder: (_, _) =>
                                      const ShimmerTradeCard(),
                                ),
                              ],
                            );
                          }
                          return ShimmerTradeList(
                            count: 5,
                            padding: AppSize.insets(
                              context,
                              left: 16,
                              right: 16,
                              top: 8,
                              bottom: 32,
                            ),
                          );
                        }

                        // Error with no data
                        if (state.status == SavedTradesStatus.failure) {
                          return _ErrorView(
                            message: state.errorMessage ??
                                'Something went wrong.',
                            onRetry: () => context
                                .read<SavedTradesBloc>()
                                .add(const SavedTradesStarted()),
                          );
                        }

                        // Empty state
                        if (state.cards.isEmpty) {
                          return _EmptyView(
                            onRefresh: () => context
                                .read<SavedTradesBloc>()
                                .add(const SavedTradesRefreshed()),
                          );
                        }

                        // List / grid
                        return RefreshIndicator(
                          color: ColorConstants.brandBlue,
                          onRefresh: () async {
                            context
                                .read<SavedTradesBloc>()
                                .add(const SavedTradesRefreshed());
                            // Wait for refreshing flag to clear.
                            await context
                                .read<SavedTradesBloc>()
                                .stream
                                .firstWhere((s) => !s.isRefreshing);
                          },
                          child: isDesktopWeb(context)
                              ? CustomScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  slivers: <Widget>[
                                    WebTradeCardGridSliver(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 8, 16, 32),
                                      itemCount: state.cards.length,
                                      itemBuilder: (context, index) {
                                        final card = state.cards[index];
                                        final trade = state.trades[index];
                                        final tid = card.tradeId;
                                        return CommonTradingCard(
                                          data: card.copyWith(
                                            isSaved: true,
                                            onSaveTap: tid == null
                                                ? null
                                                : () => context
                                                    .read<SavedTradesBloc>()
                                                    .add(
                                                        SavedTradeRemoved(tid)),
                                          ),
                                          onViewDetails: () => context.push(
                                            AppRoutingName.tradeDetails,
                                            extra: trade,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: AppSize.insets(
                                    context,
                                    left: 16,
                                    right: 16,
                                    bottom: 32,
                                  ),
                                  itemCount: state.cards.length,
                                  itemBuilder: (context, index) {
                                    final card = state.cards[index];
                                    final trade = state.trades[index];
                                    final tid = card.tradeId;
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        top: AppSize.h(context, 16),
                                        bottom: AppSize.h(context, 4),
                                      ),
                                      child: CommonTradingCard(
                                        data: card.copyWith(
                                          isSaved: true,
                                          onSaveTap: tid == null
                                              ? null
                                              : () => context
                                                  .read<SavedTradesBloc>()
                                                  .add(
                                                      SavedTradeRemoved(tid)),
                                        ),
                                        onViewDetails: () => context.push(
                                          AppRoutingName.tradeDetails,
                                          extra: trade,
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
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSize.symmetric(context, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: AppSize.r(context, 64),
              height: AppSize.r(context, 64),
              decoration: BoxDecoration(
                color: ColorConstants.brandBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_outline_rounded,
                size: AppSize.r(context, 32),
                color: ColorConstants.brandBlue,
              ),
            ),
            SizedBox(height: AppSize.h(context, 16)),
            Text(
              'No saved trades yet',
              style: TextStyleConstants.cardTitleSmall.copyWith(
                fontSize: AppSize.sp(context, 16),
                color: ColorConstants.ink,
              ),
            ),
            SizedBox(height: AppSize.h(context, 8)),
            Text(
              'Trades you save from the home feed will appear here.',
              textAlign: TextAlign.center,
              style: TextStyleConstants.caption.copyWith(
                fontSize: AppSize.sp(context, 13),
                color: ColorConstants.mute,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSize.h(context, 24)),
            TextButton(
              onPressed: onRefresh,
              child: Text(
                'Refresh',
                style: TextStyle(
                  color: ColorConstants.brandBlue,
                  fontSize: AppSize.sp(context, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSize.symmetric(context, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.wifi_off_rounded,
              size: AppSize.r(context, 40),
              color: ColorConstants.mute,
            ),
            SizedBox(height: AppSize.h(context, 12)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyleConstants.caption.copyWith(
                fontSize: AppSize.sp(context, 13),
                color: ColorConstants.mute,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSize.h(context, 20)),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: TextStyle(
                  color: ColorConstants.brandBlue,
                  fontSize: AppSize.sp(context, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
