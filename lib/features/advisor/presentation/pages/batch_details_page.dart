import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/shimmer/shimmer_widgets.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_app_notification_bar.dart';
import '../../../../core/widgets/common_button_widget.dart';
import '../../../../core/widgets/common_trading_card.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../../../core/widgets/sebi_verified_pill.dart';
import '../../../discover/data/models/discover_batch_model.dart';
import '../../../discover/domain/repositories/discover_repository.dart';
import '../../../home/data/models/home_trade_model.dart';
import '../../../home/domain/entities/home_subscription.dart';
import '../../../home/domain/entities/home_trade.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/bloc/home_event.dart';
import '../../../home/presentation/mappers/home_ui_mapper.dart';
import '../../../subscriptions/presentation/pages/subscriptions_page.dart';
import '../../../trades/presentation/widgets/trades_status_tabs.dart';

class BatchDetailsPage extends StatefulWidget {
  const BatchDetailsPage({super.key, this.planId});

  final String? planId;

  @override
  State<BatchDetailsPage> createState() => _BatchDetailsPageState();
}

class _BatchDetailsPageState extends State<BatchDetailsPage> {
  final DiscoverRepository _discover =
      GetIt.instance<DiscoverRepository>();
  final HomeRepository _home = GetIt.instance<HomeRepository>();
  final Dio _dio = GetIt.instance<Dio>();
  final HomeBloc _homeBloc = GetIt.instance<HomeBloc>();

  DiscoverBatchModel? _plan;
  List<HomeTrade> _trades = const <HomeTrade>[];
  Set<String> _savedTradeIds = const <String>{};
  String? _savingTradeId;
  HomeSubscription? _subscription;
  // Starts true — set false once data is loaded or error occurs.
  // The 80ms delay in _showSpinnerAfterDelay will keep it true only
  // for genuine network fetches; cached responses clear it before it fires.
  bool _loading = true;
  String? _error;
  TradesStatusTab _tradeTab = TradesStatusTab.active;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceSpinner = false}) async {
    final planId = widget.planId?.trim();
    if (planId == null || planId.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Batch information is unavailable.';
        });
      }
      return;
    }

    final hasData = _plan != null;

    // On revisit when data is already visible: silent background update.
    if (hasData && !forceSpinner) {
      await _fetch(planId, showSpinnerOnError: false);
      return;
    }

    // First load or explicit refresh: show spinner, but if cache responds
    // before 80ms we clear the spinner immediately so it never visually appears.
    setState(() {
      _loading = true;
      _error = null;
    });
    await _fetch(planId, showSpinnerOnError: true);
  }

  Future<void> _fetch(String planId, {required bool showSpinnerOnError}) async {
    try {
      final plan = await _discover.fetchPlan(planId);
      final results = await Future.wait<Object>(<Future<Object>>[
        _fetchBatchTrades(plan.planId),
        _home.fetchSubscriptions(),
        _home.fetchSavedTradeIds(),
      ]);
      if (!mounted) return;
      final trades = results[0] as List<HomeTrade>;
      final subscriptions = results[1] as List<HomeSubscription>;
      final savedIds = results[2] as Set<String>;
      final matching = subscriptions.where((s) => s.planId == plan.planId);
      setState(() {
        _plan = plan;
        _trades = trades;
        _savedTradeIds = savedIds;
        _subscription = matching.isEmpty ? null : matching.first;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      // Only surface an error when there is nothing to show.
      if (showSpinnerOnError && _plan == null) {
        setState(() {
          _loading = false;
          _error = 'Unable to load this batch right now.';
        });
      }
      // Otherwise silently fail — stale data stays on screen.
    }
  }

  /// Batch-details only: GET /trades/?page=&limit=&batch_id= (no analyst/status).
  /// Loads every page so all batch trades are shown, not just the first 20.
  Future<List<HomeTrade>> _fetchBatchTrades(String batchId) async {
    const limit = HomeRepository.pageSize;
    final all = <HomeTrade>[];
    var page = 1;

    while (true) {
      final res = await _dio.get<dynamic>(
        '/trades/',
        queryParameters: <String, dynamic>{
          'page': page,
          'limit': limit,
          'batch_id': batchId,
        },
      );
      if (res.statusCode != 200) break;

      final Map<String, dynamic>? dataMap =
          res.data is Map ? (res.data as Map).cast<String, dynamic>() : null;
      final List raw;
      if (res.data is List) {
        raw = res.data as List;
      } else if (dataMap != null) {
        raw = (dataMap['trades'] as List?) ??
            (dataMap['data'] is List ? dataMap['data'] as List : null) ??
            (dataMap['data'] is Map
                ? (dataMap['data'] as Map)['trades'] as List?
                : null) ??
            (dataMap['results'] as List?) ??
            const <dynamic>[];
      } else {
        raw = const <dynamic>[];
      }

      if (raw.isEmpty) break;

      all.addAll(
        raw
            .whereType<Map>()
            .map((e) => HomeTradeModel.fromJson(e.cast<String, dynamic>())),
      );

      final total = (dataMap?['total'] as num?)?.toInt();
      final loaded = all.length;
      final hasMore = total != null
          ? loaded < total
          : raw.length >= limit;
      if (!hasMore) break;
      page += 1;
    }

    return all;
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
          ? await _home.unsaveTrade(tradeId)
          : await _home.saveTrade(tradeId);
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
            child: Column(
              children: <Widget>[
                Padding(
                  padding: AppSize.insets(
                    context,
                    left: 16,
                    right: 16,
                    top: 8,
                  ),
                  child: AppBackHeader(
                    title: 'Batch Details',
                    onBack: () => context.pop(),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const ShimmerBatchDetails()
                      : _error != null
                          ? _ErrorState(
                              message: _error!,
                              onRetry: () => _load(forceSpinner: true),
                            )
                          : _content(),
                ),
              ],
            ),
          ),
          if (_savingTradeId != null)
            const Positioned.fill(child: AppLoaderOverlay()),
        ],
      ),
    );
  }

  Widget _content() {
    final plan = _plan!;
    final initials = _initials(plan.analystName);
    final visibleTrades = _trades.where((trade) {
      final live = trade.state.isLive;
      return _tradeTab == TradesStatusTab.active ? live : !live;
    }).toList();
    final about = plan.description?.trim() ?? '';
    return RefreshIndicator(
      onRefresh: () => _load(forceSpinner: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSize.insets(
          context,
          left: 16,
          right: 16,
          top: 16,
          bottom: _subscription?.isActive == true ? 110 : 30,
        ),
        children: <Widget>[
          Container(
            padding: AppSize.insets(
              context,
              left: 12,
              right: 12,
              top: 12,
              bottom: 10,
            ),
            decoration: BoxDecoration(
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(AppSize.r(context, 14)),
              border: Border.all(color: ColorConstants.line),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: ColorConstants.shadowSoft.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  plan.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleConstants.screenTitle.copyWith(
                    fontSize: AppSize.sp(context, 15),
                    color: ColorConstants.ink,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSize.h(context, 10)),
                Material(
                  color: ColorConstants.pageBackground,
                  borderRadius: BorderRadius.circular(AppSize.r(context, 10)),
                  child: InkWell(
                    onTap: () => context.push(
                      AppRoutingName.advisorProfile,
                      extra: plan.analystId,
                    ),
                    borderRadius:
                        BorderRadius.circular(AppSize.r(context, 10)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSize.w(context, 8),
                        vertical: AppSize.h(context, 6),
                      ),
                      child: Row(
                        children: <Widget>[
                          _AnalystAvatar(
                            initials: initials,
                            imageUrl: plan.analystProfilePicUrl,
                            size: AppSize.r(context, 32),
                          ),
                          SizedBox(width: AppSize.w(context, 8)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Managed by',
                                  style: TextStyleConstants.caption.copyWith(
                                    fontSize: AppSize.sp(context, 10),
                                    color: ColorConstants.mute,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  plan.analystName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyleConstants.cardTitle.copyWith(
                                    fontSize: AppSize.sp(context, 12.5),
                                    color: ColorConstants.ink,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (plan.riskLevel?.trim().isNotEmpty == true) ...<Widget>[
                            _MetaChip(
                              label: _riskLabel(plan.riskLevel!),
                              tone: _MetaChipTone.risk,
                            ),
                            SizedBox(width: AppSize.w(context, 6)),
                          ],
                          if (plan.analystSebiNumber?.isNotEmpty == true)
                            const SebiVerifiedPill(compact: true),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: AppSize.r(context, 18),
                            color: ColorConstants.soft,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (about.isNotEmpty) ...<Widget>[
                  SizedBox(height: AppSize.h(context, 12)),
                  Text(
                    about,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyleConstants.bodyMedium.copyWith(
                      fontSize: AppSize.sp(context, 11.5),
                      color: ColorConstants.mute,
                      height: 1.3,
                    ),
                  ),
                ],
                if (plan.segments.isNotEmpty) ...<Widget>[
                  SizedBox(height: AppSize.h(context, 12)),
                  _LabeledChipRow(
                    label: 'Segment',
                    chips: plan.segments
                        .map(
                          (s) => _MetaChip(
                            label: s,
                            tone: _MetaChipTone.segment,
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (plan.horizons.isNotEmpty) ...<Widget>[
                  SizedBox(height: AppSize.h(context, 6)),
                  _LabeledChipRow(
                    label: 'Horizon',
                    chips: plan.horizons
                        .map(
                          (h) => _MetaChip(
                            label: h,
                            tone: _MetaChipTone.horizon,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: AppSize.h(context, 12)),
          Row(
            children: <Widget>[
              Expanded(
                child: _SectionHeading(
                  icon: Icons.candlestick_chart_rounded,
                  title: 'Recent trades',
                ),
              ),
              _TradeStatusDropdown(
                value: _tradeTab,
                onChanged: (tab) => setState(() => _tradeTab = tab),
              ),
            ],
          ),
          SizedBox(height: AppSize.h(context, 14)),
          if (visibleTrades.isEmpty)
            Container(
              width: double.infinity,
              padding: AppSize.symmetric(context, vertical: 28),
              decoration: BoxDecoration(
                color: ColorConstants.white,
                borderRadius: BorderRadius.circular(AppSize.r(context, 18)),
                border: Border.all(color: ColorConstants.line),
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(AppSize.r(context, 10)),
                    decoration: const BoxDecoration(
                      color: ColorConstants.liveBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      color: ColorConstants.brandBlue,
                    ),
                  ),
                  SizedBox(height: AppSize.h(context, 10)),
                  Text(
                    _tradeTab == TradesStatusTab.active
                        ? 'No active trades'
                        : 'No closed trades',
                    style: TextStyleConstants.cardTitle.copyWith(
                      fontSize: AppSize.sp(context, 15),
                    ),
                  ),
                  SizedBox(height: AppSize.h(context, 4)),
                  Text(
                    _tradeTab == TradesStatusTab.active
                        ? 'Live ideas from this batch will appear here.'
                        : 'Closed trades from this batch will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyleConstants.caption.copyWith(
                      color: ColorConstants.mute,
                    ),
                  ),
                ],
              ),
            )
          else
            _RecentTradesSection(
              trades: visibleTrades,
              savedTradeIds: _savedTradeIds,
              savingTradeId: _savingTradeId,
              onToggleSaved: _toggleSaved,
              isActive: _tradeTab == TradesStatusTab.active,
            ),
          SizedBox(height: AppSize.h(context, 22)),
          _SectionHeading(
            icon: Icons.workspace_premium_outlined,
            title: 'Plans & Pricing',
          ),
          SizedBox(height: AppSize.h(context, 12)),
          ...plan.tiers.where((tier) => tier.isActive).map(_tierCard),
          if (_subscription?.isActive == true) ...<Widget>[
            SizedBox(height: AppSize.h(context, 18)),
            _ActiveSubscription(subscription: _subscription!),
          ],
        ],
      ),
    );
  }

  Widget _tierCard(DiscoverBatchTierModel tier) {
    final subscribed = _subscription?.isActive == true &&
        (_subscription?.batchId == tier.id ||
            _subscription?.planId == _plan?.planId);
    final price = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: tier.effectivePrice % 1 == 0 ? 0 : 2,
    ).format(tier.effectivePrice);
    return Container(
      margin: EdgeInsets.only(bottom: AppSize.h(context, 12)),
      padding: AppSize.insets(
        context,
        left: 14,
        right: 14,
        top: 14,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 18)),
        border: Border.all(
          color: subscribed
              ? ColorConstants.green
              : ColorConstants.brandBlue.withValues(alpha: 0.16),
          width: subscribed ? 2 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: ColorConstants.shadowSoft.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  tier.name,
                  style: TextStyleConstants.cardTitle.copyWith(
                    fontSize: AppSize.sp(context, 16),
                  ),
                ),
                Text(
                  '${tier.days} days',
                  style: TextStyleConstants.caption.copyWith(
                    color: ColorConstants.mute,
                  ),
                ),
                SizedBox(height: AppSize.h(context, 12)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      price,
                      style: TextStyleConstants.screenTitle.copyWith(
                        fontSize: AppSize.sp(context, 24),
                        color: ColorConstants.brandBlue,
                      ),
                    ),
                    if (tier.billingCycle?.isNotEmpty == true) ...<Widget>[
                      SizedBox(width: AppSize.w(context, 4)),
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: AppSize.h(context, 3),
                        ),
                        child: Text(
                          '/${tier.billingCycle!.toLowerCase()}',
                          style: TextStyleConstants.caption.copyWith(
                            color: ColorConstants.mute,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          CommonButtonWidget(
            label: subscribed ? 'Subscribed' : 'Subscribe',
            onPressed: subscribed
                ? null
                : () => context.push(
                    AppRoutingName.subscriptions,
                    extra: SubscriptionPageArgs(
                      planId: _plan!.planId,
                      analystId: _plan!.analystId,
                      batchId: tier.id,
                    ),
                  ),
            width: null,
            horizontalPadding: 16,
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  String _riskLabel(String raw) {
    switch (RiskBadge.fromString(raw)) {
      case RiskLevel.low:
        return 'Low risk';
      case RiskLevel.medium:
        return 'Medium risk';
      case RiskLevel.high:
        return 'High risk';
    }
  }
}

enum _MetaChipTone { risk, segment, horizon }

class _RecentTradesSection extends StatelessWidget {
  const _RecentTradesSection({
    required this.trades,
    required this.savedTradeIds,
    required this.savingTradeId,
    required this.onToggleSaved,
    required this.isActive,
  });

  final List<HomeTrade> trades;
  final Set<String> savedTradeIds;
  final String? savingTradeId;
  final ValueChanged<String> onToggleSaved;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveLayout.cardGridColumns(context);
    if (columns > 1) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: columns >= 3
              ? (isActive ? 235 : 225)
              : 300,
        ),
        itemCount: trades.length,
        itemBuilder: (context, index) {
          final trade = trades[index];
          return Align(
            alignment: Alignment.topCenter,
            child: CommonTradingCard(
              data: mapHomeTradeToCard(
                trade,
                savedIds: savedTradeIds,
                isSaving: savingTradeId == trade.id,
                onSaveTap: trade.id.isEmpty
                    ? null
                    : () => onToggleSaved(trade.id),
              ),
              onViewDetails: () => context.push(
                AppRoutingName.tradeDetails,
                extra: trade,
              ),
            ),
          );
        },
      );
    }

    return Column(
      children: trades
          .map(
            (trade) => Padding(
              padding: EdgeInsets.only(bottom: AppSize.h(context, 14)),
              child: CommonTradingCard(
                data: mapHomeTradeToCard(
                  trade,
                  savedIds: savedTradeIds,
                  isSaving: savingTradeId == trade.id,
                  onSaveTap: trade.id.isEmpty
                      ? null
                      : () => onToggleSaved(trade.id),
                ),
                onViewDetails: () => context.push(
                  AppRoutingName.tradeDetails,
                  extra: trade,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LabeledChipRow extends StatelessWidget {
  const _LabeledChipRow({
    required this.label,
    required this.chips,
  });

  final String label;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: AppSize.w(context, 58),
          child: Text(
            label,
            style: TextStyleConstants.caption.copyWith(
              fontSize: AppSize.sp(context, 11),
              fontWeight: FontWeight.w600,
              color: ColorConstants.mute,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (var i = 0; i < chips.length; i++) ...<Widget>[
                  if (i > 0) SizedBox(width: AppSize.w(context, 6)),
                  chips[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.tone});

  final String label;
  final _MetaChipTone tone;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;
    switch (tone) {
      case _MetaChipTone.risk:
        bg = ColorConstants.liveBg;
        fg = ColorConstants.brandBlue;
        border = ColorConstants.brandBlue.withValues(alpha: 0.2);
      case _MetaChipTone.segment:
        bg = const Color(0xFFF3F5F9);
        fg = ColorConstants.ink;
        border = ColorConstants.line;
      case _MetaChipTone.horizon:
        bg = ColorConstants.white;
        fg = ColorConstants.mute;
        border = ColorConstants.line;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w(context, 9),
        vertical: AppSize.h(context, 5),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSize.r(context, 8)),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyleConstants.caption.copyWith(
          fontSize: AppSize.sp(context, 10.5),
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1,
        ),
      ),
    );
  }
}

class _TradeStatusDropdown extends StatelessWidget {
  const _TradeStatusDropdown({
    required this.value,
    required this.onChanged,
  });

  final TradesStatusTab value;
  final ValueChanged<TradesStatusTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSize.h(context, 32),
      padding: EdgeInsets.symmetric(horizontal: AppSize.w(context, 8)),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 8)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TradesStatusTab>(
          value: value,
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: AppSize.r(context, 18),
            color: ColorConstants.mute,
          ),
          style: TextStyleConstants.caption.copyWith(
            fontSize: AppSize.sp(context, 12),
            fontWeight: FontWeight.w600,
            color: ColorConstants.ink,
          ),
          items: const <DropdownMenuItem<TradesStatusTab>>[
            DropdownMenuItem(
              value: TradesStatusTab.active,
              child: Text('Active'),
            ),
            DropdownMenuItem(
              value: TradesStatusTab.closed,
              child: Text('Closed'),
            ),
          ],
          onChanged: (tab) {
            if (tab != null) onChanged(tab);
          },
        ),
      ),
    );
  }
}

class _ActiveSubscription extends StatelessWidget {
  const _ActiveSubscription({required this.subscription});

  final HomeSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final endDate = subscription.endDate == null
        ? ''
        : DateFormat('dd MMM yyyy').format(subscription.endDate!);
    return Row(
      children: <Widget>[
        const Icon(Icons.check_circle, color: ColorConstants.green),
        SizedBox(width: AppSize.w(context, 8)),
        Expanded(
          child: Text(
            endDate.isEmpty
                ? 'Active subscription'
                : 'Active subscription — expires $endDate',
            style: TextStyleConstants.bodyMedium.copyWith(
              color: ColorConstants.green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutingName.mySubscriptions),
          child: const Text('Manage'),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: AppSize.r(context, 28),
          height: AppSize.r(context, 28),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ColorConstants.liveBg,
            borderRadius: BorderRadius.circular(AppSize.r(context, 8)),
          ),
          child: Icon(
            icon,
            size: AppSize.r(context, 16),
            color: ColorConstants.brandBlue,
          ),
        ),
        SizedBox(width: AppSize.w(context, 8)),
        Text(
          title,
          style: TextStyleConstants.cardTitle.copyWith(
            fontSize: AppSize.sp(context, 16),
          ),
        ),
      ],
    );
  }
}

class _AnalystAvatar extends StatelessWidget {
  const _AnalystAvatar({
    required this.initials,
    required this.size,
    this.imageUrl,
  });

  final String initials;
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Container(
        width: size,
        height: size,
        color: ColorConstants.white,
        alignment: Alignment.center,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Text(
                  initials,
                  style: TextStyleConstants.cardTitle.copyWith(
                    fontSize: size * 0.34,
                    color: ColorConstants.brandBlue,
                  ),
                ),
              )
            : Text(
                initials,
                style: TextStyleConstants.cardTitle.copyWith(
                  fontSize: size * 0.34,
                  color: ColorConstants.brandBlue,
                ),
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
