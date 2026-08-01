import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/services/live_prices_service.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/utils/main_tab_navigation.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/bottom_navbar.dart';
import '../../../../core/widgets/common_trading_card.dart';
import '../../../home/domain/entities/home_trade.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../home/presentation/mappers/home_ui_mapper.dart';
import '../widgets/trades_status_tabs.dart';

class TradesPage extends StatefulWidget {
  const TradesPage({super.key});

  @override
  State<TradesPage> createState() => _TradesPageState();
}

class _TradesPageState extends State<TradesPage> {
  final HomeRepository _repository = GetIt.instance<HomeRepository>();
  final LivePricesService _livePrices = GetIt.instance<LivePricesService>();
  final WebSocketService _webSocket = GetIt.instance<WebSocketService>();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<Map<String, double>>? _pricesSubscription;

  TradesStatusTab _statusTab = TradesStatusTab.active;
  List<HomeTrade> _activeTrades = const <HomeTrade>[];
  List<HomeTrade> _closedTrades = const <HomeTrade>[];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  Object? _error;

  String get _apiStatus =>
      _statusTab == TradesStatusTab.active ? 'LIVE' : 'CLOSED';

  List<HomeTrade> get _trades => _statusTab == TradesStatusTab.active
      ? _activeTrades
      : _closedTrades;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _livePrices.start();
    unawaited(_webSocket.connect());
    _pricesSubscription = _livePrices.pricesStream.listen(_applyLivePrices);
    _loadInitial();
  }

  @override
  void dispose() {
    _pricesSubscription?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    final requestedTab = _statusTab;
    final requestedStatus =
        requestedTab == TradesStatusTab.active ? 'LIVE' : 'CLOSED';
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _hasMore = true;
    });
    try {
      final result = await _repository.fetchFeed(
        page: 1,
        status: requestedStatus,
      );
      if (!mounted) return;
      setState(() {
        if (requestedTab == TradesStatusTab.active) {
          _activeTrades = _mergeLivePrices(
            result.trades,
            _livePrices.current,
          );
          _trackLiveSymbols(_activeTrades);
        } else {
          _closedTrades = result.trades;
        }
        if (_statusTab == requestedTab) {
          _page = result.page;
          _hasMore = result.hasMore;
          _loading = false;
        }
      });
    } catch (error) {
      if (!mounted || _statusTab != requestedTab) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _repository.fetchFeed(
        page: _page + 1,
        status: _apiStatus,
      );
      if (!mounted) return;
      setState(() {
        final merged = <HomeTrade>[..._trades, ...result.trades];
        if (_statusTab == TradesStatusTab.active) {
          _activeTrades = _mergeLivePrices(merged, _livePrices.current);
          _trackLiveSymbols(_activeTrades);
        } else {
          _closedTrades = merged;
        }
        _page = result.page;
        _hasMore = result.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _changeTab(TradesStatusTab tab) {
    if (tab == _statusTab) return;
    setState(() => _statusTab = tab);
    _loadInitial();
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

  void _applyLivePrices(Map<String, double> prices) {
    if (!mounted || prices.isEmpty || _activeTrades.isEmpty) return;
    final updated = _mergeLivePrices(_activeTrades, prices);
    if (_samePrices(_activeTrades, updated)) return;
    setState(() => _activeTrades = updated);
  }

  List<HomeTrade> _mergeLivePrices(
    List<HomeTrade> trades,
    Map<String, double> prices,
  ) {
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

  @override
  Widget build(BuildContext context) {
    final sectionLabel = _statusTab == TradesStatusTab.active
        ? 'Active trades'
        : 'Closed trades';

    return Scaffold(
      extendBody: true,
      backgroundColor: ColorConstants.transparent,
      body: Stack(
        children: <Widget>[
          const AppScreenBackground(
            variant: AppScreenBackgroundVariant.trades,
          ),
          RepaintBoundary(
            child: SafeArea(
              child: Padding(
                padding: AppSize.insets(context, left: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: AppSize.h(context, 18)),
                    TradesStatusTabs(
                      active: _statusTab,
                      onChanged: _changeTab,
                    ),
                    SizedBox(height: AppSize.h(context, 12)),
                    Text(
                      sectionLabel,
                      style: TextStyleConstants.bodyMedium.copyWith(
                        fontSize: AppSize.sp(context, 13),
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.mute,
                      ),
                    ),
                    SizedBox(height: AppSize.h(context, 8)),
                    Expanded(child: _buildContent()),
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
              currentIndex: 2,
              onItemSelected: (int index) {
                if (index == 2) return;
                navigateMainTab(context, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _MessageState(
        message: 'Unable to load trades',
        actionLabel: 'Retry',
        onAction: _loadInitial,
      );
    }
    if (_trades.isEmpty) {
      return _MessageState(
        message: _statusTab == TradesStatusTab.active
            ? 'No active trades yet'
            : 'No closed trades yet',
      );
    }

    return RefreshIndicator(
      color: ColorConstants.brandBlue,
      onRefresh: _loadInitial,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == _trades.length) {
                  return Padding(
                    padding: AppSize.symmetric(context, vertical: 16),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final trade = _trades[index];
                final card = mapHomeTradeToCard(trade);
                return Padding(
                  key: ValueKey<String>('trade_${trade.id}'),
                  padding: EdgeInsets.only(
                    top: AppSize.h(context, 8),
                    bottom: AppSize.h(context, 12),
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
              childCount: _trades.length + (_loadingMore ? 1 : 0),
              addRepaintBoundaries: false,
              addAutomaticKeepAlives: false,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: AppSize.h(context, 96)),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            message,
            style: TextStyleConstants.bodyMedium.copyWith(
              color: ColorConstants.mute,
              fontSize: AppSize.sp(context, 13),
            ),
          ),
          if (onAction != null) ...<Widget>[
            SizedBox(height: AppSize.h(context, 10)),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel ?? 'Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
