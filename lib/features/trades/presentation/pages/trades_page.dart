import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/services/live_prices_service.dart';
import '../../../../core/shimmer/shimmer_widgets.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/utils/main_tab_navigation.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/bottom_navbar.dart';
import '../../../../core/widgets/common_trading_card.dart';
import '../../../../core/widgets/web_side_drawer.dart';
import '../../../../core/widgets/web_trade_card_layout.dart';
import '../../../home/domain/entities/home_trade.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
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
    final bool isWeb = isDesktopWeb(context);
    final sectionLabel = _statusTab == TradesStatusTab.active
        ? 'Active trades'
        : 'Closed trades';

    final scaffold = Scaffold(
      extendBody: !isWeb,
      backgroundColor: ColorConstants.transparent,
      body: Stack(
        children: <Widget>[
          const AppScreenBackground(
            variant: AppScreenBackgroundVariant.trades,
          ),
          RepaintBoundary(
            child: SafeArea(
              bottom: !isWeb,
              child: Padding(
                padding: isWeb
                    ? const EdgeInsets.fromLTRB(20, 16, 20, 0)
                    : AppSize.insets(context, left: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: isWeb ? 8 : AppSize.h(context, 18)),
                    TradesStatusTabs(
                      active: _statusTab,
                      onChanged: _changeTab,
                    ),
                    SizedBox(height: isWeb ? 12 : AppSize.h(context, 12)),
                    Text(
                      sectionLabel,
                      style: TextStyleConstants.bodyMedium.copyWith(
                        fontSize: isWeb ? 14 : AppSize.sp(context, 13),
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.mute,
                      ),
                    ),
                    SizedBox(height: isWeb ? 8 : AppSize.h(context, 8)),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
            ),
          ),
          if (!isWeb)
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

    if (isWeb) {
      return WebSideDrawer(currentIndex: 2, child: scaffold);
    }
    return scaffold;
  }

  Widget _buildContent() {
    final bool isWeb = isDesktopWeb(context);

    if (_loading) {
      if (isWeb) {
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            WebTradeCardGridSliver(
              padding: const EdgeInsets.only(top: 4, bottom: 24),
              itemCount: 4,
              itemBuilder: (_, _) => const ShimmerTradeCard(),
            ),
          ],
        );
      }
      return ShimmerTradeList(
        count: 5,
        padding: AppSize.insets(context, left: 0, right: 0, top: 4, bottom: 88),
      );
    }
    if (_error != null) {
      return _MessageState(
        message: 'Unable to load trades',
        actionLabel: 'Retry',
        onAction: _loadInitial,
      );
    }
    if (_trades.isEmpty) {
      // For new users on the active tab show the onboarding card with steps.
      final isNewUser = GetIt.instance<HomeBloc>().state.isNewUser;
      if (_statusTab == TradesStatusTab.active && isNewUser) {
        return _NewUserEmptyState();
      }
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
          if (isWeb)
            WebTradeCardGridSliver(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: _trades.length + (_loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _trades.length) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final trade = _trades[index];
                final card = mapHomeTradeToCard(trade);
                return CommonTradingCard(
                  key: ValueKey<String>('trade_${trade.id}'),
                  data: card,
                  onViewDetails: () => context.push(
                    AppRoutingName.tradeDetails,
                    extra: trade,
                  ),
                );
              },
            )
          else ...<Widget>[
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

/// Onboarding empty-state card shown to new users on the active trades tab.
/// Mirrors the card on the Home screen.
class _NewUserEmptyState extends StatelessWidget {
  const _NewUserEmptyState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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
            borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
            border: Border.all(color: ColorConstants.line),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: ColorConstants.shadowSoft.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset(
                AssetConstants.noTradeIcon,
                width: AppSize.r(context, 72),
                height: AppSize.r(context, 72),
                fit: BoxFit.contain,
              ),
              SizedBox(height: AppSize.h(context, 16)),
              Text(
                'No live recommendations yet',
                textAlign: TextAlign.center,
                style: TextStyleConstants.cardTitle.copyWith(
                  fontSize: AppSize.sp(context, 16),
                  color: ColorConstants.ink,
                ),
              ),
              SizedBox(height: AppSize.h(context, 6)),
              Text(
                'To see trades:',
                textAlign: TextAlign.center,
                style: TextStyleConstants.bodyMedium.copyWith(
                  fontSize: AppSize.sp(context, 13),
                  color: ColorConstants.mute,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSize.h(context, 12)),
              Container(
                padding: AppSize.insets(
                  context,
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  color: ColorConstants.gray50,
                  borderRadius:
                      BorderRadius.circular(AppSize.r(context, 12)),
                  border: Border.all(color: ColorConstants.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _TradesEmptyStepRow(number: '1', text: 'Complete your KYC'),
                    SizedBox(height: AppSize.h(context, 8)),
                    _TradesEmptyStepRow(
                        number: '2', text: 'Subscribe to analysts'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TradesEmptyStepRow extends StatelessWidget {
  const _TradesEmptyStepRow({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
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
