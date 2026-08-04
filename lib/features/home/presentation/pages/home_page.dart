import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/utils/main_tab_navigation.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_filter_dialog.dart';
import '../../../../core/shimmer/shimmer_widgets.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/bottom_navbar.dart';
import '../../../../core/widgets/common_app_notification_bar.dart';
import '../../../../core/widgets/common_trading_card.dart';
import '../../../../core/widgets/web_side_drawer.dart';
import '../../../../core/widgets/web_trade_card_layout.dart';
import '../../../../../shared/models/trading_card_data.dart';
import '../../domain/entities/home_trade.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/home_search_row.dart';
import '../widgets/home_subscriptions_strip.dart';
import '../widgets/subscription_detail_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeBloc _homeBloc;

  @override
  void initState() {
    super.initState();
    _homeBloc = getIt<HomeBloc>()..add(const HomeStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>.value(
      value: _homeBloc,
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _flushbarVisible = false;

  static const List<String> _segments = <String>[
    'All',
    'Equity',
    'F&O',
    'Intraday',
    'Swing',
    'Long-term',
  ];

  static const List<String> _sortOptions = <String>[
    'Newest',
    'In profit',
    'Symbol A–Z',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      final bloc = context.read<HomeBloc>();
      if (!bloc.state.isLoadingMore && bloc.state.hasMore) {
        bloc.add(const HomeLoadMoreRequested());
      }
    }
  }

  Future<void> _openFilters(HomeState state) async {
    final result = await showAppFilterDialog(
      context: context,
      initial: AppFilterResult(
        segment: state.filterSegment,
        sort: state.sort,
      ),
      segments: _segments,
      sortOptions: _sortOptions,
    );
    if (result == null || !mounted) return;
    context.read<HomeBloc>().add(
          HomeFiltersChanged(
            segment: result.segment,
            sort: result.sort,
          ),
        );
  }

  void _onSaveTap({required String tradeId}) {
    context.read<HomeBloc>().add(HomeTradeToggleSaved(tradeId));
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb;

    final scaffold = Scaffold(
      extendBody: !isWeb,
      backgroundColor: ColorConstants.transparent,
      body: BlocListener<HomeBloc, HomeState>(
        listenWhen: (prev, curr) =>
            prev.saveTradeSuccess != curr.saveTradeSuccess ||
            prev.saveTradeError != curr.saveTradeError,
        listener: (context, state) async {
          if (_flushbarVisible) return;
          if (state.saveTradeSuccess != null) {
            _flushbarVisible = true;
            if (state.saveTradeSuccess!) {
              await CommonAppNotificationBar.success(
                context: context,
                title: 'Trade saved',
                message: 'Added to your saved trades.',
                duration: const Duration(seconds: 2),
              );
            } else {
              await CommonAppNotificationBar.error(
                context: context,
                title: 'Trade removed',
                message: 'Removed from your saved trades.',
              );
            }
            _flushbarVisible = false;
            if (context.mounted) {
              context.read<HomeBloc>().add(const HomeClearSaveFeedback());
            }
          } else if (state.saveTradeError != null) {
            _flushbarVisible = true;
            await CommonAppNotificationBar.error(
              context: context,
              title: 'Error',
              message: state.saveTradeError!,
            );
            _flushbarVisible = false;
            if (context.mounted) {
              context.read<HomeBloc>().add(const HomeClearSaveFeedback());
            }
          }
        },
        child: Stack(
          children: <Widget>[
            const AppScreenBackground(),
            RepaintBoundary(
              child: SafeArea(
                bottom: !isWeb,
                child: Padding(
                  padding: isWeb
                      ? const EdgeInsets.fromLTRB(24, 16, 24, 0)
                      : AppSize.insets(context, left: 16, right: 16, top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // ── Header row ──────────────────────────────────
                      BlocBuilder<HomeBloc, HomeState>(
                        buildWhen: (previous, current) =>
                            previous.greetingName != current.greetingName ||
                            previous.hasUnreadNotifications !=
                                current.hasUnreadNotifications,
                        builder: (BuildContext context, HomeState state) {
                          return Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'Hi, ${state.greetingName}',
                                  style:
                                      TextStyleConstants.screenTitle.copyWith(
                                    fontSize:
                                        isWeb ? 22 : AppSize.sp(context, 18),
                                  ),
                                ),
                              ),
                              _HeaderIconButton(
                                tooltip: 'Saved trades',
                                icon: Icons.bookmark_rounded,
                                onPressed: () => context
                                    .push(AppRoutingName.savedTrades),
                              ),
                              SizedBox(
                                  width: isWeb ? 8 : AppSize.w(context, 6)),
                              _HeaderIconButton(
                                tooltip: 'Notifications',
                                onPressed: () {
                                  context.read<HomeBloc>().add(
                                        const HomeNotificationsOpened(),
                                      );
                                  context.push(AppRoutingName.notifications);
                                },
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: <Widget>[
                                    Image.asset(
                                      AssetConstants.notificationIcon,
                                      width: isWeb
                                          ? 22
                                          : AppSize.r(context, 40),
                                      height: isWeb
                                          ? 22
                                          : AppSize.r(context, 40),
                                      fit: BoxFit.contain,
                                    ),
                                    if (state.hasUnreadNotifications)
                                      Positioned(
                                        top: -2,
                                        right: 0,
                                        child: Container(
                                          width: isWeb
                                              ? 8
                                              : AppSize.r(context, 10),
                                          height: isWeb
                                              ? 8
                                              : AppSize.r(context, 10),
                                          decoration: BoxDecoration(
                                            color: ColorConstants.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: ColorConstants.white,
                                              width: isWeb
                                                  ? 1.5
                                                  : AppSize.r(context, 1.5),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: isWeb ? 12 : AppSize.h(context, 10)),
                      // ── Scrollable feed ─────────────────────────────
                      Expanded(
                        child: BlocBuilder<HomeBloc, HomeState>(
                          builder: (BuildContext context, HomeState state) {
                            return RefreshIndicator(
                              color: ColorConstants.brandBlue,
                              onRefresh: () async {
                                final bloc = context.read<HomeBloc>();
                                bloc.add(const HomeRefreshed());
                                await bloc.stream.firstWhere(
                                  (HomeState s) => !s.isRefreshing,
                                );
                              },
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                slivers: <Widget>[
                                  // Search + subscriptions strip
                                  SliverToBoxAdapter(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        HomeSearchRow(
                                          controller: _searchController,
                                          onChanged: (String value) {
                                            context.read<HomeBloc>().add(
                                                  HomeSearchChanged(value),
                                                );
                                          },
                                          onFilterTap: () =>
                                              _openFilters(state),
                                          hasActiveFilters:
                                              state.filterSegment !=
                                                      'All' ||
                                                  state.sort !=
                                                      _sortOptions.first,
                                        ),
                                        SizedBox(
                                            height: isWeb
                                                ? 8
                                                : AppSize.h(context, 6)),
                                        HomeSubscriptionsStrip(
                                          items: state.subscriptions,
                                          isLoading: state.isLoading,
                                          onManageTap: () => context.push(
                                            AppRoutingName.mySubscriptions,
                                          ),
                                          onSubscriptionTap: (item) {
                                            final raw = state
                                                .rawSubscriptions
                                                .where((s) =>
                                                    (s.analystId ?? s.id) ==
                                                    item.id)
                                                .firstOrNull;
                                            if (raw != null) {
                                              showSubscriptionDetailSheet(
                                                  context, raw);
                                            }
                                          },
                                        ),
                                        SizedBox(
                                            height: isWeb
                                                ? 12
                                                : AppSize.h(context, 10)),
                                      ],
                                    ),
                                  ),
                                  // ── Loading shimmer ─────────────────
                                  if (state.isLoading) ...<Widget>[
                                    if (isWeb)
                                      WebTradeCardGridSliver(
                                        padding: const EdgeInsets.only(top: 8),
                                        itemCount: 4,
                                        itemBuilder: (_, _) =>
                                            const ShimmerTradeCard(),
                                      )
                                    else
                                      SliverToBoxAdapter(
                                        child: ShimmerScope(
                                          child: Column(
                                            children: <Widget>[
                                              SizedBox(
                                                  height:
                                                      AppSize.h(context, 8)),
                                              for (int i = 0;
                                                  i < 4;
                                                  i++) ...<Widget>[
                                                const ShimmerTradeCard(),
                                                SizedBox(
                                                    height: AppSize.h(
                                                        context, 20)),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                  ]
                                  // ── Error state ─────────────────────
                                  else if (state.status ==
                                          HomeStatus.failure &&
                                      state.cards.isEmpty)
                                    SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: _HomeError(
                                        message: state.errorMessage ??
                                            'Could not load your feed',
                                        onRetry: () => context
                                            .read<HomeBloc>()
                                            .add(const HomeStarted()),
                                      ),
                                    )
                                  // ── Empty state ──────────────────────
                                  else if (state.cards.isEmpty)
                                    SliverToBoxAdapter(
                                      child: _HomeEmptyState(state: state),
                                    )
                                  // ── Card grid (web) / list (mobile) ─
                                  else if (isWeb)
                                    WebTradeCardGridSliver(
                                      padding:
                                          const EdgeInsets.only(bottom: 32),
                                      itemCount: state.cards.length +
                                          (state.isLoadingMore ? 1 : 0),
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        if (index >= state.cards.length) {
                                          return const Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        }
                                        final TradingCardData card =
                                            state.cards[index];
                                        final HomeTrade trade =
                                            state.trades[index];
                                        final String? tid = card.tradeId;
                                        final bool saved = tid != null &&
                                            state.savedTradeIds
                                                .contains(tid);
                                        return CommonTradingCard(
                                          key: ValueKey<String>(
                                              'card_${card.symbol}_$index'),
                                          data: card.copyWith(
                                            isSaved: saved,
                                            onSaveTap: tid == null
                                                ? null
                                                : () => _onSaveTap(
                                                      tradeId: tid,
                                                    ),
                                          ),
                                          onViewDetails: () => context.push(
                                            AppRoutingName.tradeDetails,
                                            extra: trade,
                                          ),
                                        );
                                      },
                                    )
                                  else
                                    SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (BuildContext context, int index) {
                                          if (index >=
                                              state.cards.length) {
                                            return Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical:
                                                    AppSize.h(context, 16),
                                              ),
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                          final TradingCardData card =
                                              state.cards[index];
                                          final HomeTrade trade =
                                              state.trades[index];
                                          final String? tid = card.tradeId;
                                          final bool saved = tid != null &&
                                              state.savedTradeIds
                                                  .contains(tid);
                                          return Padding(
                                            key: ValueKey<String>(
                                                'card_${card.symbol}_$index'),
                                            padding: EdgeInsets.only(
                                              top: AppSize.h(context, 8),
                                              bottom:
                                                  AppSize.h(context, 8),
                                            ),
                                            child: CommonTradingCard(
                                              data: card.copyWith(
                                                isSaved: saved,
                                                onSaveTap: tid == null
                                                    ? null
                                                    : () => _onSaveTap(
                                                          tradeId: tid,
                                                        ),
                                              ),
                                              onViewDetails: () =>
                                                  context.push(
                                                AppRoutingName.tradeDetails,
                                                extra: trade,
                                              ),
                                            ),
                                          );
                                        },
                                        childCount: state.cards.length +
                                            (state.isLoadingMore ? 1 : 0),
                                        addRepaintBoundaries: false,
                                        addAutomaticKeepAlives: false,
                                      ),
                                    ),
                                  // Bottom spacer
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height: isWeb
                                          ? 24
                                          : AppSize.h(context, 88),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Mobile bottom navbar ────────────────────────────────────
            if (!isWeb)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BottomNavbar(
                  currentIndex: 0,
                  onItemSelected: (int index) {
                    if (index == 0) return;
                    navigateMainTab(context, index);
                  },
                ),
              ),
            // ── Save / unsave loader overlay ────────────────────────────
            BlocBuilder<HomeBloc, HomeState>(
              buildWhen: (prev, curr) =>
                  (prev.savingTradeId == null) !=
                  (curr.savingTradeId == null),
              builder: (BuildContext context, HomeState state) {
                if (state.savingTradeId == null) {
                  return const SizedBox.shrink();
                }
                return const Positioned.fill(child: AppLoaderOverlay());
              },
            ),
          ],
        ),
      ),
    );

    // On web, wrap in the side drawer layout
    if (isWeb) {
      return WebSideDrawer(currentIndex: 0, child: scaffold);
    }
    return scaffold;
  }
}

// ── Extracted header icon button ──────────────────────────────────────────────

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.child,
  }) : assert(icon != null || child != null,
            '_HeaderIconButton requires icon or child');

  final String tooltip;
  final VoidCallback onPressed;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb;
    return Container(
      height: 35,
      width: 35,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            ColorConstants.white,
            ColorConstants.liveBg,
          ],
        ),
        border: Border.all(
          color: ColorConstants.brandBlue.withValues(alpha: 0.18),
        ),
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: ColorConstants.brandBlue.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        icon: child ??
            Icon(
              icon,
              size: isWeb ? 18 : AppSize.r(context, 20),
              color: ColorConstants.brandBlue,
            ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({required this.state});
  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb;
    return Padding(
      padding: EdgeInsets.only(
        top: isWeb ? 24 : AppSize.h(context, 16),
        bottom: isWeb ? 32 : AppSize.h(context, 24),
      ),
      child: Container(
        width: double.infinity,
        padding: isWeb
            ? const EdgeInsets.all(32)
            : AppSize.insets(context,
                left: 20, right: 20, top: 24, bottom: 24),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(
            isWeb ? 16 : AppSize.r(context, 16),
          ),
          border: Border.all(color: ColorConstants.line),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.shadowSoft.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AssetConstants.noTradeIcon,
              width: isWeb ? 80 : AppSize.r(context, 72),
              height: isWeb ? 80 : AppSize.r(context, 72),
              fit: BoxFit.contain,
            ),
            SizedBox(height: isWeb ? 20 : AppSize.h(context, 16)),
            if (state.query.isEmpty &&
                state.filterSegment == 'All' &&
                state.isNewUser) ...[
              Text(
                'No live recommendations yet',
                textAlign: TextAlign.center,
                style: TextStyleConstants.cardTitle.copyWith(
                  fontSize: isWeb ? 18 : AppSize.sp(context, 16),
                  color: ColorConstants.ink,
                ),
              ),
              SizedBox(height: isWeb ? 8 : AppSize.h(context, 6)),
              Text(
                'To see trades:',
                textAlign: TextAlign.center,
                style: TextStyleConstants.bodyMedium.copyWith(
                  fontSize: isWeb ? 14 : AppSize.sp(context, 13),
                  color: ColorConstants.mute,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: isWeb ? 16 : AppSize.h(context, 12)),
              Container(
                padding: isWeb
                    ? const EdgeInsets.all(16)
                    : AppSize.insets(context,
                        left: 16, right: 16, top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: ColorConstants.gray50,
                  borderRadius: BorderRadius.circular(
                    isWeb ? 12 : AppSize.r(context, 12),
                  ),
                  border: Border.all(color: ColorConstants.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeEmptyStepRow(
                        number: '1', text: 'Subscribe to analysts'),
                    SizedBox(height: isWeb ? 10 : AppSize.h(context, 8)),
                    _HomeEmptyStepRow(
                        number: '2', text: 'Complete your KYC'),
                  ],
                ),
              ),
            ] else ...[
              Text(
                state.query.isEmpty && state.filterSegment == 'All'
                    ? 'No live recommendations yet'
                    : 'No recommendations match your search',
                textAlign: TextAlign.center,
                style: TextStyleConstants.bodyMedium.copyWith(
                  color: ColorConstants.mute,
                  fontSize: isWeb ? 15 : AppSize.sp(context, 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: kIsWeb
            ? const EdgeInsets.symmetric(horizontal: 24)
            : AppSize.symmetric(context, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyleConstants.bodyMedium.copyWith(
                color: ColorConstants.mute,
                fontSize: kIsWeb ? 14 : AppSize.sp(context, 13),
              ),
            ),
            SizedBox(height: kIsWeb ? 12 : AppSize.h(context, 12)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ── Step row for new-user empty state ─────────────────────────────────────────

class _HomeEmptyStepRow extends StatelessWidget {
  const _HomeEmptyStepRow({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb;
    return Row(
      children: [
        Container(
          width: isWeb ? 22 : AppSize.r(context, 20),
          height: isWeb ? 22 : AppSize.r(context, 20),
          decoration: const BoxDecoration(
            color: ColorConstants.brandBlue,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyleConstants.caption.copyWith(
              color: ColorConstants.white,
              fontWeight: FontWeight.bold,
              fontSize: isWeb ? 11 : AppSize.sp(context, 11),
            ),
          ),
        ),
        SizedBox(width: isWeb ? 10 : AppSize.w(context, 10)),
        Expanded(
          child: Text(
            text,
            style: TextStyleConstants.bodyMedium.copyWith(
              color: ColorConstants.ink,
              fontSize: isWeb ? 13 : AppSize.sp(context, 13),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
