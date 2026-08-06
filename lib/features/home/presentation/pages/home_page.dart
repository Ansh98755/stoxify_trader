import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_filter_dialog.dart';
import '../../../../core/shimmer/shimmer_widgets.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/main_tab_shell.dart';
import '../../../../core/widgets/common_app_notification_bar.dart';
import '../../../../core/widgets/common_trading_card.dart';
import '../../../../../shared/models/trading_card_data.dart';
import '../../domain/entities/home_trade.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../mappers/home_ui_mapper.dart';
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

  /// Guard flag — prevents a second flushbar from stacking while one is shown.
  bool _flushbarVisible = false;

  static const List<String> _sortOptions = <String>[
    'Newest',
    'In profit',
    'Symbol A–Z',
  ];

  static const List<String> _fallbackSegments = <String>[
    'EQUITY',
    'FNO',
    'COMMODITY',
  ];

  static const List<String> _fallbackCategories = <String>[
    'INTRADAY',
    'SWING',
    'POSITIONAL',
    'BTST',
  ];

  static const List<String> _fallbackStatuses = <String>[
    'LIVE',
    'CLOSED_BY_TARGET',
    'CLOSED_BY_SL',
    'MANUALLY_CLOSED',
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

  List<String> _facetLabels(List<String> apiValues) {
    return apiValues.map(formatTradeFacetLabel).toList();
  }

  Set<String> _labelsToApiValues(
    Set<String> labels,
    List<String> apiValues,
  ) {
    final result = <String>{};
    for (final label in labels) {
      final plain = label
          .replaceAll(RegExp(r'\s*\(\d+\)\s*$'), '')
          .trim()
          .toUpperCase()
          .replaceAll('-', '_')
          .replaceAll('&', '')
          .replaceAll(' ', '');
      for (final api in apiValues) {
        final apiUpper = api.toUpperCase();
        final apiPlain = apiUpper.replaceAll('-', '_').replaceAll(' ', '');
        final labelFormatted = formatTradeFacetLabel(api).toUpperCase();
        if (formatTradeFacetLabel(api) == label ||
            apiUpper == label.toUpperCase() ||
            labelFormatted == label.toUpperCase() ||
            apiPlain == plain ||
            (plain == 'FO' && apiUpper == 'FNO') ||
            (plain == 'LONGTERM' &&
                (apiUpper == 'LONG_TERM' || apiUpper == 'POSITIONAL')) ||
            (plain == 'LONG_TERM' &&
                (apiUpper == 'POSITIONAL' || apiUpper == 'LONG_TERM'))) {
          result.add(apiUpper);
          break;
        }
      }
    }
    return result;
  }

  Set<String> _apiValuesToLabels(Set<String> apiValues) {
    return apiValues.map(formatTradeFacetLabel).toSet();
  }

  Future<void> _openFilters(HomeState state) async {
    final facets = state.facets;
    final segmentApis = facets != null && facets.segments.isNotEmpty
        ? facets.segments.map((e) => e.value.toUpperCase()).toList()
        : _fallbackSegments;
    final categoryApis = facets != null && facets.categories.isNotEmpty
        ? facets.categories.map((e) => e.value.toUpperCase()).toList()
        : _fallbackCategories;
    final statusApis = facets != null && facets.statuses.isNotEmpty
        ? facets.statuses.map((e) => e.value.toUpperCase()).toList()
        : _fallbackStatuses;

    final result = await showAppFilterDialog(
      context: context,
      multiSelect: true,
      initial: AppFilterResult(
        segment: 'All',
        sort: state.sort,
        segments: _apiValuesToLabels(state.filterSegments),
        categories: _apiValuesToLabels(state.filterCategories),
        statuses: _apiValuesToLabels(state.filterStatuses),
      ),
      segments: _facetLabels(segmentApis),
      categories: _facetLabels(categoryApis),
      statuses: _facetLabels(statusApis),
      sortOptions: _sortOptions,
    );
    if (result == null || !mounted) return;
    context.read<HomeBloc>().add(
          HomeFiltersChanged(
            segments: _labelsToApiValues(result.segments, segmentApis),
            categories: _labelsToApiValues(result.categories, categoryApis),
            statuses: _labelsToApiValues(result.statuses, statusApis),
            sort: result.sort,
          ),
        );
  }

  /// Fires the save/unsave toggle — the BlocListener above handles the flushbar.
  void _onSaveTap({required String tradeId}) {
    context.read<HomeBloc>().add(HomeTradeToggleSaved(tradeId));
  }

  @override
  Widget build(BuildContext context) {
    final hPad = ResponsiveLayout.contentHorizontalPadding(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: ColorConstants.transparent,
      body: MainTabShell(
        currentIndex: 0,
        child: BlocListener<HomeBloc, HomeState>(
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
          // RepaintBoundary isolates the content layer from the animated
          // background so that BlocBuilder setState repaints independently
          // and is never blocked by BackdropFilter compositing in BottomNavbar.
          RepaintBoundary(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, AppSize.h(context, 8), hPad, 0),
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
                                  color: ColorConstants.brandBlue
                                      .withValues(alpha: 0.18),
                                ),
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: ColorConstants.brandBlue
                                        .withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () =>
                                    context.push(AppRoutingName.savedTrades),
                                tooltip: 'Saved trades',
                                icon: Icon(
                                  Icons.bookmark_rounded,
                                  size: AppSize.r(context, 20),
                                  color: ColorConstants.brandBlue,
                                ),
                              ),
                            ),
                            SizedBox(width: AppSize.w(context, 6)),
                            Container(
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
                                  color: ColorConstants.brandBlue
                                      .withValues(alpha: 0.18),
                                ),
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: ColorConstants.brandBlue
                                        .withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
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
                                      width: AppSize.r(context, 40),
                                      height: AppSize.r(context, 40),
                                      fit: BoxFit.contain,
                                    ),
                                    if (state.hasUnreadNotifications)
                                      Positioned(
                                        top: -2,
                                        right: 0,
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
                                        hintText: 'Search Trades',
                                        onChanged: (String value) {
                                          context.read<HomeBloc>().add(
                                                HomeSearchChanged(value),
                                              );
                                        },
                                        onFilterTap: () =>
                                            _openFilters(state),
                                        hasActiveFilters:
                                            state.hasActiveFilters,
                                      ),
                                      SizedBox(height: AppSize.h(context, 6)),
                                      HomeSubscriptionsStrip(
                                        items: state.subscriptions,
                                        isLoading: state.isLoading,
                                        onManageTap: () => context.push(
                                          AppRoutingName.mySubscriptions,
                                        ),
                                        onSubscriptionTap: (item) {
                                          final raw = state.rawSubscriptions
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
                                          height: AppSize.h(context, 10)),
                                    ],
                                  ),
                                ),
                                if (state.isLoading) ...<Widget>[
                                  Builder(
                                    builder: (context) {
                                      final bool webGrid =
                                          ResponsiveLayout.useWebDesktopShell(
                                        context,
                                      );
                                      if (webGrid) {
                                        const columns = 3;
                                        return SliverToBoxAdapter(
                                          child: ShimmerScope(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                top: AppSize.h(context, 8),
                                                bottom: AppSize.h(context, 8),
                                              ),
                                              child: GridView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                gridDelegate:
                                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: columns,
                                                  mainAxisSpacing: 12,
                                                  crossAxisSpacing: 12,
                                                  mainAxisExtent: 230,
                                                ),
                                                // Two rows × 3 cards
                                                itemCount: columns * 2,
                                                itemBuilder:
                                                    (context, index) =>
                                                        const ShimmerTradeCard(),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return SliverToBoxAdapter(
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
                                      );
                                    },
                                  ),
                                ]
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
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: AppSize.h(context, 16),
                                        bottom: AppSize.h(context, 24),
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: AppSize.insets(
                                          context,
                                          left: 20,
                                          right: 20,
                                          top: 24,
                                          bottom: 24,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ColorConstants.white,
                                          borderRadius: BorderRadius.circular(
                                            AppSize.r(context, 16),
                                          ),
                                          border: Border.all(
                                            color: ColorConstants.line,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: ColorConstants.shadowSoft
                                                  .withValues(alpha: 0.04),
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
                                              width: AppSize.r(context, 72),
                                              height: AppSize.r(context, 72),
                                              fit: BoxFit.contain,
                                            ),
                                            SizedBox(
                                              height: AppSize.h(context, 16),
                                            ),
                                            if (state.query.isEmpty &&
                                                !state.hasActiveFilters &&
                                                state.isNewUser) ...[
                                              Text(
                                                'No live recommendations yet',
                                                textAlign: TextAlign.center,
                                                style: TextStyleConstants
                                                    .cardTitle
                                                    .copyWith(
                                                  fontSize: AppSize.sp(
                                                    context,
                                                    16,
                                                  ),
                                                  color: ColorConstants.ink,
                                                ),
                                              ),
                                              SizedBox(
                                                height: AppSize.h(
                                                  context,
                                                  6,
                                                ),
                                              ),
                                              Text(
                                                'To see trades:',
                                                textAlign: TextAlign.center,
                                                style: TextStyleConstants
                                                    .bodyMedium
                                                    .copyWith(
                                                  fontSize: AppSize.sp(
                                                    context,
                                                    13,
                                                  ),
                                                  color: ColorConstants.mute,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(
                                                height: AppSize.h(
                                                  context,
                                                  12,
                                                ),
                                              ),
                                              Container(
                                                padding: AppSize.insets(
                                                  context,
                                                  left: 16,
                                                  right: 16,
                                                  top: 12,
                                                  bottom: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: ColorConstants
                                                      .gray50,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    AppSize.r(context, 12),
                                                  ),
                                                  border: Border.all(
                                                    color:
                                                        ColorConstants.line,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    _HomeEmptyStepRow(
                                                      number: '1',
                                                      text:
                                                          'Subscribe to analysts',
                                                    ),
                                                    SizedBox(
                                                      height: AppSize.h(
                                                        context,
                                                        8,
                                                      ),
                                                    ),
                                                    _HomeEmptyStepRow(
                                                      number: '2',
                                                      text:
                                                          'Complete your KYC',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ] else ...[
                                              Text(
                                                state.query.isEmpty &&
                                                        !state.hasActiveFilters
                                                    ? 'No live recommendations yet'
                                                    : 'No recommendations match your search',
                                                textAlign: TextAlign.center,
                                                style: TextStyleConstants
                                                    .bodyMedium
                                                    .copyWith(
                                                  color: ColorConstants.mute,
                                                  fontSize: AppSize.sp(
                                                    context,
                                                    14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                else if (ResponsiveLayout.cardGridColumns(
                                      context) >
                                  1)
                                  SliverPadding(
                                    padding: EdgeInsets.only(
                                      top: AppSize.h(context, 4),
                                      bottom: AppSize.h(context, 8),
                                    ),
                                    sliver: _HomeTradeGrid(
                                      cards: state.cards,
                                      trades: state.trades,
                                      savedTradeIds: state.savedTradeIds,
                                      isLoadingMore: state.isLoadingMore,
                                      columns:
                                          ResponsiveLayout.cardGridColumns(
                                        context,
                                      ),
                                      onSave: (String tradeId) =>
                                          _onSaveTap(tradeId: tradeId),
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
                                        return _HomeTradeTile(
                                          key: ValueKey<String>(
                                            'card_${state.cards[index].symbol}_$index',
                                          ),
                                          card: state.cards[index],
                                          trade: state.trades[index],
                                          isSaved: state.cards[index]
                                                      .tradeId !=
                                                  null &&
                                              state.savedTradeIds.contains(
                                                state.cards[index].tradeId!,
                                              ),
                                          onSave: (String tradeId) =>
                                              _onSaveTap(tradeId: tradeId),
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
                                    height: ResponsiveLayout
                                            .useWebDesktopShell(context)
                                        ? AppSize.h(context, 24)
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
          BlocBuilder<HomeBloc, HomeState>(
            buildWhen: (prev, curr) =>
                (prev.savingTradeId == null) != (curr.savingTradeId == null),
            builder: (BuildContext context, HomeState state) {
              if (state.savingTradeId == null) return const SizedBox.shrink();
              return const Positioned.fill(
                child: AppLoaderOverlay(),
              );
            },
          ),
        ],
      ),
      ),
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

class _HomeEmptyStepRow extends StatelessWidget {
  const _HomeEmptyStepRow({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppSize.r(context, 20),
          height: AppSize.r(context, 20),
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
              fontSize: AppSize.sp(context, 11),
            ),
          ),
        ),
        SizedBox(width: AppSize.w(context, 10)),
        Expanded(
          child: Text(
            text,
            style: TextStyleConstants.bodyMedium.copyWith(
              color: ColorConstants.ink,
              fontSize: AppSize.sp(context, 13),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeTradeTile extends StatelessWidget {
  const _HomeTradeTile({
    super.key,
    required this.card,
    required this.trade,
    required this.isSaved,
    required this.onSave,
  });

  final TradingCardData card;
  final HomeTrade trade;
  final bool isSaved;
  final ValueChanged<String> onSave;

  @override
  Widget build(BuildContext context) {
    final tid = card.tradeId;
    return Padding(
      padding: EdgeInsets.only(
        top: AppSize.h(context, 8),
        bottom: AppSize.h(context, 8),
      ),
      child: CommonTradingCard(
        data: card.copyWith(
          isSaved: isSaved,
          onSaveTap: tid == null ? null : () => onSave(tid),
        ),
        onViewDetails: () => context.push(
          AppRoutingName.tradeDetails,
          extra: trade,
        ),
      ),
    );
  }
}

class _HomeTradeGrid extends StatelessWidget {
  const _HomeTradeGrid({
    required this.cards,
    required this.trades,
    required this.savedTradeIds,
    required this.isLoadingMore,
    required this.columns,
    required this.onSave,
  });

  final List<TradingCardData> cards;
  final List<HomeTrade> trades;
  final Set<String> savedTradeIds;
  final bool isLoadingMore;
  final int columns;
  final ValueChanged<String> onSave;

  @override
  Widget build(BuildContext context) {
    final count = cards.length + (isLoadingMore ? 1 : 0);
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        // Fit the existing card content without trailing empty space.
        mainAxisExtent: columns >= 3 ? 230 : 300,
      ),
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          if (index >= cards.length) {
            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final card = cards[index];
          final tid = card.tradeId;
          final saved =
              tid != null && savedTradeIds.contains(tid);
          return Align(
            alignment: Alignment.topCenter,
            child: _HomeTradeTile(
              key: ValueKey<String>('grid_${card.symbol}_$index'),
              card: card,
              trade: trades[index],
              isSaved: saved,
              onSave: onSave,
            ),
          );
        },
        childCount: count,
      ),
    );
  }
}
