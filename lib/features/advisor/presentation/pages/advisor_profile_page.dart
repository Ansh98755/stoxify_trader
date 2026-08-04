import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/shimmer/shimmer_widgets.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_batch_card.dart';
import '../../../../core/widgets/common_button_widget.dart';
import '../../../../core/widgets/common_trading_card.dart';
import '../../../../core/widgets/sebi_verified_pill.dart';
import '../../../../core/widgets/web_trade_card_layout.dart';
import '../../../discover/data/models/discover_analyst_model.dart';
import '../../../discover/data/models/discover_batch_model.dart';
import '../../../discover/domain/repositories/discover_repository.dart';
import '../../../discover/presentation/mappers/discover_ui_mapper.dart';
import '../../../home/domain/entities/home_trade.dart';
import '../../../home/domain/entities/home_subscription.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../home/presentation/mappers/home_ui_mapper.dart';
import '../../../subscriptions/presentation/pages/subscriptions_page.dart';

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
  final ScrollController _tradesController = ScrollController();

  DiscoverAnalystModel? _profile;
  double? _discoverWinRate;
  List<DiscoverBatchModel> _batches = const <DiscoverBatchModel>[];
  List<HomeTrade> _trades = const <HomeTrade>[];
  bool _hasActiveSubscription = false;
  Set<String> _activePlanIds = const <String>{};
  Set<String> _activeBatchIds = const <String>{};
  int _tab = 0;
  int _tradePage = 0;
  bool _hasMoreTrades = true;
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
    _tradesController.addListener(_onTradesScroll);
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
    _tradesController
      ..removeListener(_onTradesScroll)
      ..dispose();
    super.dispose();
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
        _tradePage = 0;
        _hasMoreTrades = true;
      });
    } else {
      _tradePage = 0;
      _hasMoreTrades = true;
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
          status: 'LIVE,CLOSED',
        ),
        _homeRepository.fetchSubscriptions(),
      ]);
      if (!mounted) return;
      final feed = results[2] as HomeFeedPage;
      final profile = results[0] as DiscoverAnalystModel;
      final subscriptions = results[3] as List<HomeSubscription>;
      final batches = results[1] as List<DiscoverBatchModel>;
      final batchPlanIds = batches.map((b) => b.planId).toSet();
      final hasActiveSub = subscriptions.any(
        (s) =>
            s.isActive &&
            (s.analystId == analystId ||
                (s.planId != null && batchPlanIds.contains(s.planId))),
      );
      setState(() {
        _profile = profile;
        _discoverWinRate = profile.winRate;
        _batches = batches;
        _trades = feed.trades;
        _tradePage = feed.page;
        _hasMoreTrades = feed.hasMore;
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

  void _onTradesScroll() {
    if (_tab != 1 || !_tradesController.hasClients) return;
    final position = _tradesController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadMoreTrades();
    }
  }

  Future<void> _loadMoreTrades() async {
    final analystId = _analystId;
    if (analystId == null ||
        _loadingMoreTrades ||
        !_hasMoreTrades ||
        _loading) {
      return;
    }
    setState(() => _loadingMoreTrades = true);
    try {
      final page = await _homeRepository.fetchFeed(
        page: _tradePage + 1,
        analystId: analystId,
        status: 'LIVE,CLOSED',
      );
      if (!mounted) return;
      setState(() {
        _trades = <HomeTrade>[..._trades, ...page.trades];
        _tradePage = page.page;
        _hasMoreTrades = page.hasMore;
        _loadingMoreTrades = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMoreTrades = false);
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
        ],
      ),
    );
  }

  Widget _buildProfile(BuildContext context) {
    final profile = _profile!;
    final winRate =
        '${((_discoverWinRate ?? profile.winRate) * 100).round()}%';
    final averagePnl =
        '${profile.avgPnlPercent >= 0 ? '+' : ''}${profile.avgPnlPercent.toStringAsFixed(2)}%';
    final initials = _initials(profile.name);
    final bool isWeb = kIsWeb;
    final EdgeInsets pagePad = isWeb
        ? const EdgeInsets.fromLTRB(20, 4, 20, 0)
        : AppSize.insets(context, left: 16, right: 16, top: 4);

    return Column(
      children: <Widget>[
        Padding(
          padding: pagePad,
          child: Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: ColorConstants.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
                    side: const BorderSide(color: ColorConstants.line),
                  ),
                  child: InkWell(
                    onTap: () => context.pop(),
                    borderRadius:
                        BorderRadius.circular(AppSize.r(context, 12)),
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
              Column(
                children: <Widget>[
                  _ProfileAvatar(
                    imageUrl: profile.profilePicUrl,
                    initials: initials,
                  ),
                  SizedBox(height: AppSize.h(context, 8)),
                  Text(
                    profile.name,
                    textAlign: TextAlign.center,
                    style: TextStyleConstants.cardTitle.copyWith(
                      fontSize: isWeb ? 22 : AppSize.sp(context, 20),
                    ),
                  ),
                  if (profile.sebiLicenseNumber != null) ...<Widget>[
                    SizedBox(height: AppSize.h(context, 3)),
                    Text(
                      profile.sebiLicenseNumber!,
                      textAlign: TextAlign.center,
                      style: TextStyleConstants.caption.copyWith(
                        fontSize: AppSize.sp(context, 12),
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.brandBlue,
                      ),
                    ),
                    SizedBox(height: AppSize.h(context, 6)),
                    const SebiVerifiedPill(),
                  ],
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: isWeb ? 12 : AppSize.h(context, 10)),
        // Stats strip: on web, cap width and center so it does not stretch edge-to-edge.
        Padding(
          padding: isWeb
              ? const EdgeInsets.symmetric(horizontal: 20)
              : AppSize.symmetric(context, horizontal: 16),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWeb ? 560 : double.infinity,
              ),
              child: Container(
                width: double.infinity,
                padding: isWeb
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                    : AppSize.insets(
                        context,
                        left: 14,
                        right: 14,
                        top: 12,
                        bottom: 12,
                      ),
                decoration: BoxDecoration(
                  color: ColorConstants.white,
                  borderRadius: BorderRadius.circular(
                    isWeb ? 14 : AppSize.r(context, 16),
                  ),
                  border: Border.all(color: ColorConstants.line),
                ),
                child: Row(
                  children: <Widget>[
                    _Stat(winRate, 'Win rate', ColorConstants.green),
                    _Stat(
                      averagePnl,
                      'Avg P&L',
                      profile.avgPnlPercent < 0
                          ? ColorConstants.red
                          : ColorConstants.green,
                    ),
                    _Stat(
                      profile.totalTrades.toString(),
                      'Trades',
                      ColorConstants.ink,
                    ),
                    _Stat(
                      profile.totalSubscribers.toString(),
                      'Subscribers',
                      ColorConstants.ink,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: isWeb ? 14 : AppSize.h(context, 16)),
        Padding(
          padding: isWeb
              ? const EdgeInsets.symmetric(horizontal: 20)
              : AppSize.symmetric(context, horizontal: 16),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWeb ? 720 : double.infinity,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _ProfileTab(
                      label: 'Batches & Plans',
                      selected: _tab == 0,
                      onTap: () => setState(() => _tab = 0),
                    ),
                  ),
                  SizedBox(width: isWeb ? 10 : AppSize.w(context, 8)),
                  Expanded(
                    child: _ProfileTab(
                      label: 'Recent Trades',
                      selected: _tab == 1,
                      onTap: () => setState(() => _tab = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: isWeb ? 12 : AppSize.h(context, 12)),
        Expanded(child: _tab == 0 ? _buildBatches() : _buildTrades()),
      ],
    );
  }

  Widget _buildBatches() {
    final bool isWeb = kIsWeb;
    if (_loadingBatches) {
      if (isWeb) {
        return _WebTwoColScroll(
          itemCount: 4,
          itemBuilder: (_, __) => const ShimmerBatchCard(),
        );
      }
      return ShimmerScope(
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: AppSize.insets(context, left: 16, right: 16, top: 6, bottom: 110),
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: EdgeInsets.only(bottom: AppSize.h(context, 18)),
            child: const ShimmerBatchCard(),
          ),
        ),
      );
    }
    if (_batches.isEmpty) {
      return const _EmptyList(message: 'No active batches or plans.');
    }

    Widget batchCard(int index) {
      final batch = DiscoverUiMapper.toBatchData(_batches[index]);
      return CommonBatchCard(
        data: batch,
        showAnalystProfile: false,
        isSubscribed: _activePlanIds.contains(_batches[index].planId) ||
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
      );
    }

    if (isWeb) {
      return RefreshIndicator(
        color: ColorConstants.brandBlue,
        onRefresh: () => _loadProfile(silent: true),
        child: _WebTwoColScroll(
          itemCount: _batches.length,
          itemBuilder: (_, index) => batchCard(index),
        ),
      );
    }

    return RefreshIndicator(
      color: ColorConstants.brandBlue,
      onRefresh: () => _loadProfile(silent: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSize.insets(
          context,
          left: 16,
          right: 16,
          top: 6,
          bottom: 110,
        ),
        itemCount: _batches.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSize.h(context, 18)),
            child: batchCard(index),
          );
        },
      ),
    );
  }

  Widget _buildTrades() {
    final bool isWeb = kIsWeb;
    if (_loadingTrades) {
      if (isWeb) {
        return _WebTwoColScroll(
          itemCount: 4,
          itemBuilder: (_, __) => const ShimmerTradeCard(),
        );
      }
      return ShimmerScope(
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: AppSize.insets(context, left: 16, right: 16, top: 6, bottom: 110),
          itemCount: 4,
          itemBuilder: (_, __) => Padding(
            padding: EdgeInsets.only(bottom: AppSize.h(context, 12)),
            child: const ShimmerTradeCard(),
          ),
        ),
      );
    }
    if (_trades.isEmpty) {
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
        return _SubscribeEmptyState(
          priceLabel: priceLabel,
          onSubscribe: () => context.push(AppRoutingName.subscriptions),
        );
      }
      return const _EmptyList(message: 'No recent trades yet.');
    }

    Widget tradeCard(int index) {
      final trade = _trades[index];
      return CommonTradingCard(
        data: mapHomeTradeToCard(trade),
        onViewDetails: () => context.push(
          AppRoutingName.tradeDetails,
          extra: trade,
        ),
      );
    }

    if (isWeb) {
      return RefreshIndicator(
        color: ColorConstants.brandBlue,
        onRefresh: () => _loadProfile(silent: true),
        child: _WebTwoColScroll(
          controller: _tradesController,
          itemCount: _trades.length + (_loadingMoreTrades ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _trades.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return tradeCard(index);
          },
        ),
      );
    }

    return RefreshIndicator(
      color: ColorConstants.brandBlue,
      onRefresh: () => _loadProfile(silent: true),
      child: ListView.builder(
        controller: _tradesController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSize.insets(
          context,
          left: 16,
          right: 16,
          top: 6,
          bottom: 110,
        ),
        itemCount: _trades.length + (_loadingMoreTrades ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _trades.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: AppSize.h(context, 12)),
              child: ShimmerScope(
                child: ShimmerTradeCard(),
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.only(bottom: AppSize.h(context, 12)),
            child: tradeCard(index),
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

/// Web-only: max 2 cards per row (same idea as Home trade feed).
class _WebTwoColScroll extends StatelessWidget {
  const _WebTwoColScroll({
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final int rowCount = (itemCount + 1) ~/ 2;
    return ListView.separated(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
      itemCount: rowCount,
      separatorBuilder: (_, _) =>
          const SizedBox(height: WebTradeCardLayout.mainSpacing),
      itemBuilder: (context, rowIndex) {
        final int left = rowIndex * 2;
        final int right = left + 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: itemBuilder(context, left)),
            const SizedBox(width: WebTradeCardLayout.crossSpacing),
            Expanded(
              child: right < itemCount
                  ? itemBuilder(context, right)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageUrl, required this.initials});

  final String? imageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        initials,
        style: TextStyleConstants.cardTitle.copyWith(
          color: ColorConstants.white,
          fontSize: AppSize.sp(context, 18),
        ),
      ),
    );
    return Container(
      width: AppSize.r(context, 64),
      height: AppSize.r(context, 64),
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

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb;
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyleConstants.numeric.copyWith(
              fontSize: isWeb ? 15 : AppSize.sp(context, 14),
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: isWeb ? 3 : AppSize.h(context, 2)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyleConstants.caption.copyWith(
              fontSize: isWeb ? 11 : AppSize.sp(context, 10),
              color: ColorConstants.mute,
            ),
          ),
        ],
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
          padding: AppSize.symmetric(context, vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
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
