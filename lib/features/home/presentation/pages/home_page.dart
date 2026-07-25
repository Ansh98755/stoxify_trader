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
import '../../../../core/widgets/app_filter_dialog.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/bottom_navbar.dart';
import '../../../../core/widgets/common_app_notification_bar.dart';
import '../../../../core/widgets/common_trading_card.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/home_search_row.dart';
import '../widgets/home_subscriptions_strip.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (_) => getIt<HomeBloc>()..add(const HomeStarted()),
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

  /// Guard flag — prevents a second flushbar from stacking while one is shown.
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

  /// Fires the save/unsave toggle and shows a flushbar.
  /// The guard [_flushbarVisible] prevents multiple flushbars stacking.
  Future<void> _onSaveTap({
    required String tradeId,
    required bool currentlySaved,
  }) async {
    if (_flushbarVisible) return;
    _flushbarVisible = true;

    // Dispatch toggle immediately — UI label flips without waiting for flushbar.
    context.read<HomeBloc>().add(HomeTradeToggleSaved(tradeId));

    await CommonAppNotificationBar.success(
      context: context,
      title: currentlySaved ? 'Trade removed' : 'Trade saved',
      message: currentlySaved
          ? 'Removed from your saved trades.'
          : 'Added to your saved trades.',
      duration: const Duration(seconds: 2),
    );

    _flushbarVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: ColorConstants.transparent,
      body: Stack(
        children: <Widget>[
          const AppScreenBackground(),
          // RepaintBoundary isolates the content layer from the animated
          // background so that BlocBuilder setState repaints independently
          // and is never blocked by BackdropFilter compositing in BottomNavbar.
          RepaintBoundary(
            child: SafeArea(
              child: Padding(
                padding: AppSize.insets(context, left: 16, right: 16, top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
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
                                style: TextStyleConstants.screenTitle.copyWith(
                                  fontSize: AppSize.sp(context, 18),
                                ),
                              ),
                            ),
                            Container(
                              height: 36,
                              width: 42,
                              decoration: BoxDecoration(
                                color: ColorConstants.white,
                                border: Border.all(color: ColorConstants.line),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  context.read<HomeBloc>().add(
                                        const HomeNotificationsOpened(),
                                      );
                                  context.push(AppRoutingName.notifications);
                                },
                                tooltip: 'Notifications',
                                icon: Stack(
                                  clipBehavior: Clip.none,
                                  children: <Widget>[
                                    Image.asset(
                                      AssetConstants.notificationIcon,
                                      width: AppSize.r(context, 25),
                                      height: AppSize.r(context, 25),
                                      fit: BoxFit.contain,
                                    ),
                                    if (state.hasUnreadNotifications)
                                      Positioned(
                                        top: -3,
                                        right: 2,
                                        child: Container(
                                          width: AppSize.r(context, 10),
                                          height: AppSize.r(context, 10),
                                          decoration: BoxDecoration(
                                            color: ColorConstants.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: ColorConstants.white,
                                              width: AppSize.r(context, 1.5),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: AppSize.h(context, 10)),
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
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: <Widget>[
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
                                            state.filterSegment != 'All' ||
                                                state.sort !=
                                                    _sortOptions.first,
                                      ),
                                      SizedBox(height: AppSize.h(context, 6)),
                                      HomeSubscriptionsStrip(
                                        items: state.subscriptions,
                                        isLoading: state.isLoading,
                                        onManageTap: () => context.push(
                                          AppRoutingName.mySubscriptions,
                                        ),
                                        onSubscriptionTap: (_) =>
                                            context.push(
                                          AppRoutingName.advisorProfile,
                                        ),
                                      ),
                                      SizedBox(
                                          height: AppSize.h(context, 10)),
                                    ],
                                  ),
                                ),
                                if (state.isLoading)
                                  const SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
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
                                else if (state.cards.isEmpty)
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: AppSize.h(context, 40),
                                        ),
                                        child: Text(
                                          state.query.isEmpty &&
                                                  state.filterSegment == 'All'
                                              ? 'No live recommendations yet.\nSubscribe to an analyst to see trades here.'
                                              : 'No recommendations match your search',
                                          textAlign: TextAlign.center,
                                          style: TextStyleConstants.bodyMedium
                                              .copyWith(
                                            color: ColorConstants.mute,
                                            fontSize: AppSize.sp(context, 13),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (BuildContext context, int index) {
                                        if (index >= state.cards.length) {
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
                                        final String? tid = card.tradeId;
                                        final bool saved = tid != null &&
                                            state.savedTradeIds.contains(tid);
                                        return Padding(
                                          key: ValueKey<String>(
                                              'card_${card.symbol}_$index'),
                                          padding: EdgeInsets.only(
                                            top: AppSize.h(context, 8),
                                            bottom: AppSize.h(context, 8),
                                          ),
                                          child: CommonTradingCard(
                                            data: card.copyWith(
                                              isSaved: saved,
                                              onSaveTap: tid == null
                                                  ? null
                                                  : () => _onSaveTap(
                                                        tradeId: tid,
                                                        currentlySaved: saved,
                                                      ),
                                            ),
                                            onViewDetails: () => context.push(
                                              AppRoutingName.tradeDetails,
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
                                SliverToBoxAdapter(
                                  child: SizedBox(
                                      height: AppSize.h(context, 88)),
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
        ],
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({
    required this.message,
    required this.onRetry,
  });

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
            SizedBox(height: AppSize.h(context, 12)),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
