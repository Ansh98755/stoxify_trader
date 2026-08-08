import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/network/ws_trade_event.dart';
import '../../../../core/services/live_prices_service.dart';
import '../../../../core/shimmer/shimmer_widgets.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_batch_card.dart';
import '../../../../core/widgets/common_button_widget.dart';
import '../../../../core/widgets/common_trading_card.dart';
import '../../../../core/widgets/sebi_verified_pill.dart';
import '../../../../core/widgets/segment_tag_chip.dart';
import '../../../discover/data/models/discover_analyst_model.dart';
import '../../../discover/data/models/discover_batch_model.dart';
import '../../../discover/domain/repositories/discover_repository.dart';
import '../../../discover/presentation/mappers/discover_ui_mapper.dart';
import '../../../home/data/ws_trade_merge.dart';
import '../../../home/domain/entities/home_trade.dart';
import '../../../home/domain/entities/home_subscription.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../../home/presentation/mappers/home_ui_mapper.dart';
import '../../../subscriptions/presentation/pages/subscriptions_page.dart';
import '../../../../core/widgets/common_app_notification_bar.dart';

class AdvisorProfilePage extends StatefulWidget {
  const AdvisorProfilePage({
    super.key,
    this.analystId,
    this.initialProfile,
  });

  final String? analystId;
  final DiscoverAnalystModel? initialProfile;

  @override
  State<AdvisorProfilePage> createState() => _AdvisorProfilePageState();
}

class _AdvisorProfilePageState extends State<AdvisorProfilePage> {
  final DiscoverRepository _discoverRepository =
      GetIt.instance<DiscoverRepository>();
  final HomeRepository _homeRepository = GetIt.instance<HomeRepository>();
  final HomeBloc _homeBloc = GetIt.instance<HomeBloc>();
  final LivePricesService _livePrices = GetIt.instance<LivePricesService>();
  final WebSocketService _webSocket = GetIt.instance<WebSocketService>();
  StreamSubscription<Map<String, double>>? _pricesSubscription;
  StreamSubscription<WsTradeEvent>? _tradeWsSubscription;
  StreamSubscription<Map<String, dynamic>>? _notifSubscription;
  StreamSubscription<void>? _wsReconnectSubscription;

  DiscoverAnalystModel? _profile;
  double? _discoverWinRate;
  List<DiscoverBatchModel> _batches = const <DiscoverBatchModel>[];
  List<HomeTrade> _activeTrades = const <HomeTrade>[];
  List<HomeTrade> _closedTrades = const <HomeTrade>[];
  Set<String> _savedTradeIds = const <String>{};
  String? _savingTradeId;
  bool _hasActiveSubscription = false;
  Set<String> _activePlanIds = const <String>{};
  Set<String> _activeBatchIds = const <String>{};
  int _section = 0; // 0 batches, 1 trades
  int _tradeFilter = 0; // 0 active, 1 closed (only when _section == 1)
  int _activeTradePage = 0;
  int _closedTradePage = 0;
  bool _hasMoreActiveTrades = true;
  bool _hasMoreClosedTrades = true;
  // Start without a spinner if we already have an initialProfile — the
  // background fetch for batches and trades will complete without a full-page
  // loading state.
  bool _loading = true;
  bool _loadingBatches = false;
  bool _loadingTrades = false;
  bool _loadingMoreTrades = false;
  String? _error;

  String? get _analystId {
    final id = (widget.initialProfile?.userId ?? widget.analystId)?.trim();
    return id == null || id.isEmpty ? null : id;
  }

  @override
  void initState() {
    super.initState();
    _livePrices.start();
    unawaited(_webSocket.connect());
    _pricesSubscription = _livePrices.pricesStream.listen(_applyLivePrices);
    _tradeWsSubscription = _webSocket.tradeEvents.listen(_onWsTradeEvent);
    _notifSubscription =
        _webSocket.notificationUpdates.listen(_onTradeNotification);
    _wsReconnectSubscription = _webSocket.reconnected.listen((_) {
      if (mounted) unawaited(_loadProfile(silent: true));
    });
    // If we already have initialProfile, seed it immediately so the screen
    // renders without a spinner while background data loads.
    if (widget.initialProfile != null) {
      _profile = widget.initialProfile;
      _discoverWinRate = widget.initialProfile!.winRate;
      _loading = false;
      // Tab content still needs to load — show per-tab shimmer
      _loadingBatches = true;
      _loadingTrades = true;
    }
    _loadProfile();
  }

  @override
  void dispose() {
    _pricesSubscription?.cancel();
    _tradeWsSubscription?.cancel();
    _notifSubscription?.cancel();
    _wsReconnectSubscription?.cancel();
    super.dispose();
  }

  void _onTradeNotification(Map<String, dynamic> data) {
    final type = (data['type'] as String?)?.toUpperCase() ?? '';
    if (type == 'TRADE_MODIFIED') {
      final id = WsTradeEvent.resolveTradeId(data);
      if (id != null) unawaited(_refreshTradeById(id));
      return;
    }
    if (type.startsWith('TRADE_')) {
      unawaited(_loadProfile(silent: true));
    }
  }

  Future<void> _refreshTradeById(String tradeId) async {
    try {
      final fresh = await _homeRepository.fetchTrade(tradeId);
      if (!mounted) return;
      setState(() {
        _activeTrades = _mergeLivePrices(
          _upsertById(_activeTrades, fresh, tradeId),
          _livePrices.current,
        );
        _closedTrades = _upsertById(_closedTrades, fresh, tradeId);
        _trackLiveSymbols(_activeTrades);
      });
    } catch (_) {
      if (mounted) await _loadProfile(silent: true);
    }
  }

  List<HomeTrade> _upsertById(
    List<HomeTrade> list,
    HomeTrade fresh,
    String requestedId,
  ) {
    final next = List<HomeTrade>.from(list);
    final index = next.indexWhere(
      (t) => t.id == fresh.id || t.id == requestedId,
    );
    if (index >= 0) {
      next[index] = fresh;
      return next;
    }
    return <HomeTrade>[fresh, ...next];
  }

  void _onWsTradeEvent(WsTradeEvent event) {
    if (!mounted) return;
    final analystId = _analystId;
    final payloadAnalyst = event.payload['analyst_id']?.toString();
    if (analystId != null &&
        payloadAnalyst != null &&
        payloadAnalyst.isNotEmpty &&
        payloadAnalyst != analystId) {
      return;
    }

    final result = WsTradeMerge.applyToActiveClosed(
      active: _activeTrades,
      closed: _closedTrades,
      kind: event.kind,
      payload: event.payload,
    );
    if (result.needsRefetch && event.tradeId != null) {
      unawaited(_refreshTradeById(event.tradeId!));
      return;
    }
    if (result.needsRefetch) {
      unawaited(_loadProfile(silent: true));
      return;
    }
    setState(() {
      _activeTrades = _mergeLivePrices(result.active, _livePrices.current);
      _closedTrades = result.closed;
      _trackLiveSymbols(_activeTrades);
    });
  }

  void _trackLiveSymbols(Iterable<HomeTrade> trades) {
    final symbols = <String>{};
    for (final trade in trades) {
      if (!trade.state.isLive) continue;
      symbols.addAll(
        trade.symbol
            .split(' / ')
            .map((symbol) => symbol.trim())
            .where((symbol) => symbol.isNotEmpty),
      );
    }
    _livePrices.trackAdditional(symbols);
  }

  List<HomeTrade> _mergeLivePrices(
    List<HomeTrade> trades,
    Map<String, double> prices,
  ) {
    if (prices.isEmpty) return trades;
    return trades.map((trade) {
      if (!trade.state.isLive) return trade;
      double? price = prices[trade.symbol];
      if (price == null && trade.symbol.contains(' / ')) {
        price = prices[trade.symbol.split(' / ').first.trim()];
      }
      return price == null || price == trade.ltp
          ? trade
          : trade.copyWith(ltp: price);
    }).toList();
  }

  bool _samePrices(List<HomeTrade> before, List<HomeTrade> after) {
    if (before.length != after.length) return false;
    for (var i = 0; i < before.length; i++) {
      if (before[i].ltp != after[i].ltp) return false;
    }
    return true;
  }

  void _applyLivePrices(Map<String, double> prices) {
    if (!mounted || prices.isEmpty || _activeTrades.isEmpty) return;
    final updated = _mergeLivePrices(_activeTrades, prices);
    if (_samePrices(_activeTrades, updated)) return;
    setState(() => _activeTrades = updated);
  }

  Future<void> _loadProfile({bool silent = false}) async {
    final analystId = _analystId;
    if (analystId == null) {
      setState(() {
        _loading = false;
        _error = 'Analyst information is unavailable.';
      });
      return;
    }

    // Only show the full-page spinner on the very first load when we have
    // no data at all. Subsequent calls (retry, pull-to-refresh) or calls
    // when initialProfile was already seeded run silently.
    final hasData = _profile != null;
    if (!hasData && !silent) {
      setState(() {
        _loading = true;
        _error = null;
        _activeTradePage = 0;
        _closedTradePage = 0;
        _hasMoreActiveTrades = true;
        _hasMoreClosedTrades = true;
      });
    } else {
      _activeTradePage = 0;
      _closedTradePage = 0;
      _hasMoreActiveTrades = true;
      _hasMoreClosedTrades = true;
      if (silent) {
        setState(() {
          _loadingBatches = true;
          _loadingTrades = true;
        });
      }
    }

    try {
      final profileFuture = widget.initialProfile == null
          ? _discoverRepository.fetchAnalystProfile(analystId)
          : Future<DiscoverAnalystModel>.value(widget.initialProfile);
      final results = await Future.wait<Object>(<Future<Object>>[
        profileFuture,
        _discoverRepository.fetchAnalystBatches(analystId),
        _homeRepository.fetchFeed(
          page: 1,
          analystId: analystId,
          status: 'LIVE',
        ),
        _homeRepository.fetchFeed(
          page: 1,
          analystId: analystId,
          status: 'CLOSED',
        ),
        _homeRepository.fetchSubscriptions(),
        _homeRepository.fetchSavedTradeIds(),
      ]);
      if (!mounted) return;
      final liveFeed = results[2] as HomeFeedPage;
      final closedFeed = results[3] as HomeFeedPage;
      final profile = results[0] as DiscoverAnalystModel;
      final subscriptions = results[4] as List<HomeSubscription>;
      final batches = results[1] as List<DiscoverBatchModel>;
      final savedIds = results[5] as Set<String>;
      final batchPlanIds = batches.map((b) => b.planId).toSet();
      final hasActiveSub = subscriptions.any(
        (s) =>
            s.isActive &&
            (s.analystId == analystId ||
                (s.planId != null && batchPlanIds.contains(s.planId))),
      );
      final activeTrades =
          _mergeLivePrices(liveFeed.trades, _livePrices.current);
      final closedTrades = closedFeed.trades
          .where((trade) => !trade.state.isLive)
          .toList();
      setState(() {
        _profile = profile;
        _discoverWinRate = profile.winRate;
        _batches = batches;
        _activeTrades = activeTrades;
        _closedTrades = closedTrades;
        _savedTradeIds = savedIds;
        _activeTradePage = liveFeed.page;
        _closedTradePage = closedFeed.page;
        _hasMoreActiveTrades = liveFeed.hasMore;
        _hasMoreClosedTrades = closedFeed.hasMore;
        _hasActiveSubscription = hasActiveSub;
        _activePlanIds = subscriptions
            .where((subscription) => subscription.isActive)
            .map((subscription) => subscription.planId)
            .whereType<String>()
            .toSet();
        _activeBatchIds = subscriptions
            .where((subscription) => subscription.isActive)
            .map((subscription) => subscription.batchId)
            .whereType<String>()
            .toSet();
        _loading = false;
        _loadingBatches = false;
        _loadingTrades = false;
        _error = null;
      });
      _trackLiveSymbols(activeTrades);
      if (widget.initialProfile == null) {
        _loadDiscoverWinRate(analystId);
      }
    } catch (_) {
      if (!mounted) return;
      if (_profile == null) {
        setState(() {
          _loading = false;
          _loadingBatches = false;
          _loadingTrades = false;
          _error = 'Unable to load this analyst right now.';
        });
      } else {
        setState(() {
          _loadingBatches = false;
          _loadingTrades = false;
        });
      }
    }
  }

  Future<void> _loadDiscoverWinRate(String analystId) async {
    try {
      final analysts = await _discoverRepository.fetchAnalysts(page: 1);
      final matching = analysts.where((item) => item.userId == analystId);
      if (!mounted || matching.isEmpty) return;
      setState(() => _discoverWinRate = matching.first.winRate);
    } catch (_) {
      // The by-ID profile already provides a backend-derived fallback from
      // performance.winning_trades / performance.total_trades.
    }
  }

  bool _handleTradesScrollNotification(ScrollNotification notification) {
    if (_section != 1) return false;
    if (notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 300) {
      _loadMoreTrades();
    }
    return false;
  }

  Future<void> _loadMoreTrades() async {
    final analystId = _analystId;
    final isClosed = _tradeFilter == 1;
    final hasMore = isClosed ? _hasMoreClosedTrades : _hasMoreActiveTrades;
    if (analystId == null || _loadingMoreTrades || !hasMore || _loading) {
      return;
    }
    setState(() => _loadingMoreTrades = true);
    try {
      final page = await _homeRepository.fetchFeed(
        page: (isClosed ? _closedTradePage : _activeTradePage) + 1,
        analystId: analystId,
        status: isClosed ? 'CLOSED' : 'LIVE',
      );
      if (!mounted) return;
      if (isClosed) {
        final incoming =
            page.trades.where((trade) => !trade.state.isLive).toList();
        final merged = <HomeTrade>[..._closedTrades, ...incoming];
        setState(() {
          _closedTrades = merged;
          _closedTradePage = page.page;
          _hasMoreClosedTrades = page.hasMore;
          _loadingMoreTrades = false;
        });
      } else {
        final merged = _mergeLivePrices(
          <HomeTrade>[..._activeTrades, ...page.trades],
          _livePrices.current,
        );
        setState(() {
          _activeTrades = merged;
          _activeTradePage = page.page;
          _hasMoreActiveTrades = page.hasMore;
          _loadingMoreTrades = false;
        });
        _trackLiveSymbols(merged);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMoreTrades = false);
    }
  }

  Future<void> _toggleSaved(String tradeId) async {
    if (tradeId.isEmpty || _savingTradeId != null) return;

    final wasSaved = _savedTradeIds.contains(tradeId);
    final optimistic = Set<String>.from(_savedTradeIds);
    if (wasSaved) {
      optimistic.remove(tradeId);
    } else {
      optimistic.add(tradeId);
    }
    setState(() {
      _savedTradeIds = optimistic;
      _savingTradeId = tradeId;
    });

    try {
      final bool saved = wasSaved
          ? await _homeRepository.unsaveTrade(tradeId)
          : await _homeRepository.saveTrade(tradeId);
      if (!mounted) return;

      setState(() {
        final next = Set<String>.from(_savedTradeIds);
        if (saved) {
          next.add(tradeId);
        } else {
          next.remove(tradeId);
        }
        _savedTradeIds = next;
        _savingTradeId = null;
      });

      _homeBloc.add(HomeSavedTradeIdsUpdated(_savedTradeIds));

      if (saved) {
        await CommonAppNotificationBar.success(
          context: context,
          title: 'Trade saved',
          message: 'Added to your saved trades.',
        );
      } else {
        await CommonAppNotificationBar.error(
          context: context,
          title: 'Trade removed',
          message: 'Removed from your saved trades.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final rolledBack = Set<String>.from(_savedTradeIds);
        if (wasSaved) {
          rolledBack.add(tradeId);
        } else {
          rolledBack.remove(tradeId);
        }
        _savedTradeIds = rolledBack;
        _savingTradeId = null;
      });
      await CommonAppNotificationBar.error(
        context: context,
        title: 'Error',
        message: wasSaved
            ? 'Failed to remove trade. Please try again.'
            : 'Failed to save trade. Please try again.',
      );
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
            bottom: false,
            child: _loading
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: AppSize.insets(context, left: 16, right: 16, top: 4),
                        child: Material(
                          color: ColorConstants.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
                            side: const BorderSide(color: ColorConstants.line),
                          ),
                          child: InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
                            child: SizedBox(
                              width: AppSize.r(context, 40),
                              height: AppSize.r(context, 40),
                              child: Icon(Icons.arrow_back_rounded, size: AppSize.r(context, 20)),
                            ),
                          ),
                        ),
                      ),
                      const Expanded(child: ShimmerAdvisorProfile()),
                    ],
                  )
                : _error != null
                    ? _ErrorState(message: _error!, onRetry: () => _loadProfile())
                    : _buildProfile(context),
          ),
          if (_savingTradeId != null)
            const Positioned.fill(child: AppLoaderOverlay()),
        ],
      ),
    );
  }

  Widget _buildProfile(BuildContext context) {
    final profile = _profile!;
    final winRate =
        DiscoverUiMapper.formatWinRateLabel(_discoverWinRate ?? profile.winRate);
    final averagePnl = DiscoverUiMapper.formatAvgPnlLabel(profile.avgPnlPercent);
    final initials = _initials(profile.name);
    final registration =
        DiscoverUiMapper.formatRegistrationTypeLabel(profile.registrationType);
    final license = (profile.sebiLicenseNumber ?? '').trim();
    final focusLabels = <String>[
      ...profile.segmentsCovered,
      ...profile.horizonsCovered,
      ...profile.specialization,
    ]
        .map((e) => formatTradeFacetLabel(e.trim()))
        .where((e) => e.isNotEmpty)
        .toSet()
        .take(4)
        .toList();
    final metaParts = <String>[
      if (registration.isNotEmpty) registration,
    ];
    final bool pnlNegative = profile.avgPnlPercent < 0;

    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSize.insets(context, left: 16, right: 16, top: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(top: AppSize.h(context, 4)),
                          child: _ProfileAvatar(
                            imageUrl: profile.profilePicUrl,
                            initials: initials,
                            size: AppSize.r(context, 72),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Material(
                            color: ColorConstants.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSize.r(context, 12),
                              ),
                              side: const BorderSide(color: ColorConstants.line),
                            ),
                            child: InkWell(
                              onTap: () => context.pop(),
                              borderRadius: BorderRadius.circular(
                                AppSize.r(context, 12),
                              ),
                              child: SizedBox(
                                width: AppSize.r(context, 40),
                                height: AppSize.r(context, 40),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  size: AppSize.r(context, 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Positioned(
                          right: 0,
                          top: 0,
                          child: SebiVerifiedPill(compact: true),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSize.h(context, 10)),
                  Text(
                    profile.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleConstants.cardTitle.copyWith(
                      fontSize: AppSize.sp(context, 18),
                    ),
                  ),
                  if (metaParts.isNotEmpty) ...<Widget>[
                    SizedBox(height: AppSize.h(context, 6)),
                    Text(
                      metaParts.join(' · '),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleConstants.bodyMedium.copyWith(
                        fontSize: AppSize.sp(context, 12.5),
                        color: ColorConstants.mute,
                        height: 1.2,
                      ),
                    ),
                  ],
                  if (license.isNotEmpty) ...<Widget>[
                    SizedBox(height: AppSize.h(context, 4)),
                    Text(
                      license,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleConstants.caption.copyWith(
                        fontSize: AppSize.sp(context, 11),
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.brandBlue,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                  if (focusLabels.isNotEmpty) ...<Widget>[
                    SizedBox(height: AppSize.h(context, 10)),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSize.w(context, 6),
                      runSpacing: AppSize.h(context, 6),
                      children: focusLabels
                          .map((label) => SegmentTagChip(label: label))
                          .toList(),
                    ),
                  ],
                  SizedBox(height: AppSize.h(context, 14)),
                  Container(
                    width: double.infinity,
                    padding: AppSize.insets(
                      context,
                      left: 10,
                      right: 10,
                      top: 12,
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConstants.white,
                      borderRadius:
                          BorderRadius.circular(AppSize.r(context, 14)),
                      border: Border.all(
                        color: ColorConstants.navy.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        _ProfileMetric(
                          value: winRate,
                          label: 'Win rate',
                          valueColor: ColorConstants.green,
                          iconAsset: AssetConstants.winRateAnalystCard,
                        ),
                        _ProfileMetricDivider(),
                        _ProfileMetric(
                          value: averagePnl,
                          label: 'Avg P&L',
                          valueColor: pnlNegative
                              ? ColorConstants.red
                              : ColorConstants.green,
                          iconAsset: AssetConstants.avgPlAnalystCard,
                        ),
                        _ProfileMetricDivider(),
                        _ProfileMetric(
                          value: profile.totalTrades == null
                              ? 'N/A'
                              : '${profile.totalTrades}',
                          label: 'Trades',
                          valueColor: profile.totalTrades == null
                              ? ColorConstants.soft
                              : ColorConstants.ink,
                          iconAsset: AssetConstants.subscribersAnalystCard,
                        ),
                        _ProfileMetricDivider(),
                        _ProfileMetric(
                          value: '${profile.experienceYears}',
                          label: 'Yrs exp.',
                          valueColor: ColorConstants.ink,
                          iconAsset: AssetConstants.subscribersAnalystCard,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSize.h(context, 12)),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SectionHeaderDelegate(
              height: AppSize.h(context, 48),
              child: ColoredBox(
                color: ColorConstants.white,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSize.w(context, 16),
                    AppSize.h(context, 4),
                    AppSize.w(context, 16),
                    AppSize.h(context, 8),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _ProfileTab(
                          label: 'Batches',
                          selected: _section == 0,
                          onTap: () => setState(() => _section = 0),
                        ),
                      ),
                      SizedBox(width: AppSize.w(context, 8)),
                      Expanded(
                        child: _TradesFilterTab(
                          selected: _section == 1,
                          tradeFilter: _tradeFilter,
                          onFilterSelected: (filter) {
                            setState(() {
                              _section = 1;
                              _tradeFilter = filter;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ];
      },
      body: _section == 0
          ? _buildBatches()
          : _buildTrades(liveOnly: _tradeFilter == 0),
    );
  }

  Widget _buildBatches() {
    final columns = ResponsiveLayout.cardGridColumns(context);
    final hPad = ResponsiveLayout.contentHorizontalPadding(context);
    final bottomPad =
        ResponsiveLayout.useWebDesktopShell(context) ? 24.0 : 110.0;

    if (_loadingBatches) {
      if (columns > 1) {
        return ShimmerScope(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 6, hPad, bottomPad),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: columns >= 3 ? 260 : 280,
            ),
            itemCount: columns * 2,
            itemBuilder: (_, __) => const Align(
              alignment: Alignment.topCenter,
              child: ShimmerBatchCard(),
            ),
          ),
        );
      }
      return ShimmerScope(
        child: ListView.builder(
          padding: AppSize.insets(context, left: 16, right: 16, top: 8, bottom: 110),
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: EdgeInsets.only(bottom: AppSize.h(context, 18)),
            child: const ShimmerBatchCard(),
          ),
        ),
      );
    }
    if (_batches.isEmpty) {
      return ListView(
        padding: AppSize.insets(context, left: 16, right: 16, top: 48),
        children: const <Widget>[
          _EmptyList(message: 'No active batches or plans.'),
        ],
      );
    }

    if (columns > 1) {
      return RefreshIndicator(
        color: ColorConstants.brandBlue,
        onRefresh: () => _loadProfile(silent: true),
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          clipBehavior: Clip.none,
          padding: EdgeInsets.fromLTRB(hPad, 6, hPad, bottomPad),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: columns >= 3 ? 260 : 280,
          ),
          itemCount: _batches.length,
          itemBuilder: (context, index) {
            final batch = DiscoverUiMapper.toBatchData(_batches[index]);
            return Align(
              alignment: Alignment.topCenter,
              child: CommonBatchCard(
                data: batch,
                showAnalystProfile: false,
                isSubscribed:
                    _activePlanIds.contains(_batches[index].planId) ||
                    _batches[index].tiers.any(
                      (tier) => _activeBatchIds.contains(tier.id),
                    ),
                onTap: () => context.push(
                  AppRoutingName.batchDetails,
                  extra: _batches[index].planId,
                ),
                onSubscribe: () => context.push(
                  AppRoutingName.subscriptions,
                  extra: SubscriptionPageArgs(
                    planId: _batches[index].planId,
                    analystId: _batches[index].analystId,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      color: ColorConstants.brandBlue,
      onRefresh: () => _loadProfile(silent: true),
      child: ListView.builder(
        padding: AppSize.insets(
          context,
          left: 16,
          right: 16,
          top: 14,
          bottom: 110,
        ),
        itemCount: _batches.length,
        itemBuilder: (context, index) {
          final batch = DiscoverUiMapper.toBatchData(_batches[index]);
          return Padding(
            padding: EdgeInsets.only(
              top: AppSize.h(context, 8),
              bottom: AppSize.h(context, 8),
            ),
            child: CommonBatchCard(
              data: batch,
              showAnalystProfile: false,
              isSubscribed:
                  _activePlanIds.contains(_batches[index].planId) ||
                  _batches[index].tiers.any(
                    (tier) => _activeBatchIds.contains(tier.id),
                  ),
              onTap: () => context.push(
                AppRoutingName.batchDetails,
                extra: _batches[index].planId,
              ),
              onSubscribe: () => context.push(
                AppRoutingName.subscriptions,
                extra: SubscriptionPageArgs(
                  planId: _batches[index].planId,
                  analystId: _batches[index].analystId,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrades({required bool liveOnly}) {
    final columns = ResponsiveLayout.cardGridColumns(context);
    final hPad = ResponsiveLayout.contentHorizontalPadding(context);
    final bottomPad =
        ResponsiveLayout.useWebDesktopShell(context) ? 24.0 : 110.0;

    if (_loadingTrades) {
      if (columns > 1) {
        return ShimmerScope(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 6, hPad, bottomPad),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: columns >= 3
                  ? (liveOnly ? 235 : 180)
                  : 300,
            ),
            itemCount: columns * 2,
            itemBuilder: (_, __) => const Align(
              alignment: Alignment.topCenter,
              child: ShimmerTradeCard(),
            ),
          ),
        );
      }
      return ShimmerScope(
        child: ListView.builder(
          padding: AppSize.insets(
            context,
            left: 16,
            right: 16,
            top: 8,
            bottom: 110,
          ),
          itemCount: 4,
          itemBuilder: (_, __) => Padding(
            padding: EdgeInsets.only(bottom: AppSize.h(context, 12)),
            child: const ShimmerTradeCard(),
          ),
        ),
      );
    }

    final List<HomeTrade> filtered = liveOnly
        ? _activeTrades
        : _closedTrades.where((trade) => !trade.state.isLive).toList();

    if (filtered.isEmpty) {
      if (!_hasActiveSubscription) {
        String? priceLabel;
        if (_batches.isNotEmpty) {
          final cheapest = _batches.reduce(
            (a, b) => a.startingPrice <= b.startingPrice ? a : b,
          );
          final suffix = DiscoverUiMapper.billingSuffix(
            cheapest.cheapestTier?.billingCycle,
          );
          priceLabel = '₹${cheapest.startingPrice.round()}$suffix';
        }
        return ListView(
          padding: AppSize.insets(context, left: 16, right: 16, top: 24),
          children: <Widget>[
            _SubscribeEmptyState(
              priceLabel: priceLabel,
              onSubscribe: () => context.push(AppRoutingName.subscriptions),
            ),
          ],
        );
      }
      return ListView(
        padding: AppSize.insets(context, left: 16, right: 16, top: 40),
        children: <Widget>[
          _EmptyList(
            message: liveOnly
                ? 'No active trades right now.'
                : 'No closed trades yet.',
          ),
        ],
      );
    }

    final itemCount = filtered.length + (_loadingMoreTrades ? 1 : 0);

    if (columns > 1) {
      return NotificationListener<ScrollNotification>(
        onNotification: _handleTradesScrollNotification,
        child: RefreshIndicator(
          color: ColorConstants.brandBlue,
          onRefresh: () => _loadProfile(silent: true),
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            padding: EdgeInsets.fromLTRB(hPad, 6, hPad, bottomPad),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: columns >= 3
                  ? (liveOnly ? 235 : 225)
                  : 300,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index >= filtered.length) {
                return const Align(
                  alignment: Alignment.topCenter,
                  child: ShimmerTradeCard(),
                );
              }
              final trade = filtered[index];
              return Align(
                alignment: Alignment.topCenter,
                child: CommonTradingCard(
                  data: mapHomeTradeToCard(
                    trade,
                    savedIds: _savedTradeIds,
                    isSaving: _savingTradeId == trade.id,
                    onSaveTap: trade.id.isEmpty
                        ? null
                        : () => _toggleSaved(trade.id),
                  ),
                  onViewDetails: () => context.push(
                    AppRoutingName.tradeDetails,
                    extra: trade,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleTradesScrollNotification,
      child: RefreshIndicator(
        color: ColorConstants.brandBlue,
        onRefresh: () => _loadProfile(silent: true),
        child: ListView.builder(
          padding: AppSize.insets(
            context,
            left: 16,
            right: 16,
            top: 14,
            bottom: 110,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == filtered.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: AppSize.h(context, 12)),
                child: const ShimmerScope(
                  child: ShimmerTradeCard(),
                ),
              );
            }
            final trade = filtered[index];
            final card = mapHomeTradeToCard(
              trade,
              savedIds: _savedTradeIds,
              isSaving: _savingTradeId == trade.id,
              onSaveTap: trade.id.isEmpty ? null : () => _toggleSaved(trade.id),
            );
            return Padding(
              padding: EdgeInsets.only(
                top: AppSize.h(context, 8),
                bottom: AppSize.h(context, 8),
              ),
              child: CommonTradingCard(
                data: card,
                onViewDetails: () => context.push(
                  AppRoutingName.tradeDetails,
                  extra: trade,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SectionHeaderDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: height, child: child);
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}

class _ProfileMetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: AppSize.h(context, 36),
      margin: AppSize.symmetric(context, horizontal: 2),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            ColorConstants.transparent,
            ColorConstants.line,
            ColorConstants.transparent,
          ],
        ),
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.iconAsset,
  });

  final String value;
  final String label;
  final Color valueColor;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(
            iconAsset,
            width: AppSize.r(context, 16),
            height: AppSize.r(context, 16),
          ),
          SizedBox(height: AppSize.h(context, 4)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyleConstants.cardTitleSmall.copyWith(
              fontSize: AppSize.sp(context, 13),
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSize.h(context, 2)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyleConstants.caption.copyWith(
              fontSize: AppSize.sp(context, 10),
              color: ColorConstants.mute,
            ),
          ),
        ],
      ),
    );
  }
}

class _TradesFilterTab extends StatelessWidget {
  const _TradesFilterTab({
    required this.selected,
    required this.tradeFilter,
    required this.onFilterSelected,
  });

  final bool selected;
  final int tradeFilter;
  final ValueChanged<int> onFilterSelected;

  String get _label => tradeFilter == 0 ? 'Active' : 'Closed';

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final choice = await showMenu<int>(
      context: context,
      position: position,
      color: ColorConstants.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        side: const BorderSide(color: ColorConstants.line),
      ),
      items: <PopupMenuEntry<int>>[
        PopupMenuItem<int>(
          value: 0,
          child: Text(
            'Active trades',
            style: TextStyleConstants.bodyMedium.copyWith(
              fontSize: AppSize.sp(context, 13),
              fontWeight:
                  tradeFilter == 0 ? FontWeight.w700 : FontWeight.w500,
              color: tradeFilter == 0
                  ? ColorConstants.brandBlue
                  : ColorConstants.ink,
            ),
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Text(
            'Closed trades',
            style: TextStyleConstants.bodyMedium.copyWith(
              fontSize: AppSize.sp(context, 13),
              fontWeight:
                  tradeFilter == 1 ? FontWeight.w700 : FontWeight.w500,
              color: tradeFilter == 1
                  ? ColorConstants.brandBlue
                  : ColorConstants.ink,
            ),
          ),
        ),
      ],
    );

    if (choice != null) onFilterSelected(choice);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ColorConstants.white : ColorConstants.gray50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        side: BorderSide(
          color: selected
              ? ColorConstants.navy.withValues(alpha: 0.35)
              : ColorConstants.line,
        ),
      ),
      child: InkWell(
        onTap: () => _openMenu(context),
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        child: Padding(
          padding: AppSize.symmetric(context, vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  selected ? _label : 'Trades',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleConstants.bodyMedium.copyWith(
                    fontSize: AppSize.sp(context, 12),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? ColorConstants.ink : ColorConstants.mute,
                  ),
                ),
              ),
              SizedBox(width: AppSize.w(context, 2)),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: AppSize.r(context, 18),
                color: selected ? ColorConstants.ink : ColorConstants.mute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.initials,
    this.size,
  });

  final String? imageUrl;
  final String initials;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final double dim = size ?? AppSize.r(context, 64);
    final fallback = Center(
      child: Text(
        initials,
        style: TextStyleConstants.cardTitle.copyWith(
          color: ColorConstants.white,
          fontSize: AppSize.sp(context, dim > 56 ? 18 : 15),
        ),
      ),
    );
    return Container(
      width: dim,
      height: dim,
      padding: EdgeInsets.all(AppSize.r(context, 2.5)),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ColorConstants.brandBlueLight, width: 2),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: <Color>[
              ColorConstants.brandBlueLight,
              ColorConstants.brandBlue,
            ],
          ),
        ),
        child: ClipOval(
          child: imageUrl == null
              ? fallback
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ColorConstants.white : ColorConstants.gray50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        side: BorderSide(
          color: selected
              ? ColorConstants.navy.withValues(alpha: 0.35)
              : ColorConstants.line,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        child: Padding(
          padding: AppSize.symmetric(context, vertical: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyleConstants.bodyMedium.copyWith(
              fontSize: AppSize.sp(context, 12),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? ColorConstants.ink : ColorConstants.mute,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscribeEmptyState extends StatefulWidget {
  const _SubscribeEmptyState({
    required this.onSubscribe,
    this.priceLabel,
  });

  final VoidCallback onSubscribe;
  final String? priceLabel;

  @override
  State<_SubscribeEmptyState> createState() => _SubscribeEmptyStateState();
}

class _SubscribeEmptyStateState extends State<_SubscribeEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.priceLabel;
    return Center(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Padding(
            padding: AppSize.symmetric(context, horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: AppSize.r(context, 72),
                  height: AppSize.r(context, 72),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorConstants.brandBlue.withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: AppSize.r(context, 32),
                    color: ColorConstants.brandBlue,
                  ),
                ),
                SizedBox(height: AppSize.h(context, 16)),
                Text(
                  'Subscribe to view analyst\'s trades',
                  textAlign: TextAlign.center,
                  style: TextStyleConstants.bodyMedium.copyWith(
                    fontSize: AppSize.sp(context, 15),
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.ink,
                  ),
                ),
                SizedBox(height: AppSize.h(context, 8)),
                Text(
                  price != null
                      ? 'Get live & past trade signals from this analyst starting at $price.'
                      : 'Get live & past trade signals from this analyst.',
                  textAlign: TextAlign.center,
                  style: TextStyleConstants.bodyMedium.copyWith(
                    fontSize: AppSize.sp(context, 13),
                    color: ColorConstants.mute,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: AppSize.h(context, 24)),
                CommonButtonWidget(
                  label: price != null ? 'Subscribe from $price' : 'Subscribe',
                  onPressed: widget.onSubscribe,
                  width: null,
                  height: AppSize.h(context, 46),
                  borderRadius: 14,
                  horizontalPadding: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyleConstants.bodyMedium.copyWith(
          color: ColorConstants.mute,
          fontSize: AppSize.sp(context, 13),
        ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
