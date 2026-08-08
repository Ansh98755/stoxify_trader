import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes/app_routing_name.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/network/ws_trade_event.dart';
import '../../../../core/services/live_prices_service.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/common_app_notification_bar.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../../core/widgets/common_button_widget.dart';
import '../../../../core/widgets/sebi_verified_pill.dart';
import '../../../../core/widgets/tapered_divider.dart';
import '../../../../core/widgets/trade_signal_timeline.dart';
import '../../../../core/widgets/trade_symbol_avatar.dart';
import '../../../home/data/ws_trade_merge.dart';
import '../../../home/domain/entities/home_trade.dart';
import '../../../home/domain/repositories/home_repository.dart';

final _inrPrecise = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

String _money(double v) => _inrPrecise.format(v);
String _signedPct(double? v) {
  if (v == null) return '—';
  final sign = v >= 0 ? '+' : '';
  return '$sign${v.toStringAsFixed(2)}%';
}

String _riskRewardRatio(HomeTrade? trade) {
  if (trade == null) return '—';

  final double risk = (trade.entry - trade.sl).abs();
  final double reward = (trade.finalTarget - trade.entry).abs();
  if (risk <= 0 || reward <= 0) return '—';

  return '1 : ${(reward / risk).toStringAsFixed(2)}';
}

String _modificationFieldLabel(String field) {
  switch (field.toLowerCase()) {
    case 'sl':
    case 'stop_loss':
      return 'Stop loss';
    case 'targets':
      return 'Targets';
    default:
      return field
          .split('_')
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' ');
  }
}

bool _usesModificationComparison(String field) {
  switch (field.toLowerCase()) {
    case 'targets':
    case 'sl':
    case 'stop_loss':
      return true;
    default:
      return false;
  }
}

/// Prefer the trade's analyst display name over raw IDs (e.g. ANALYST_…).
String _modificationAuthorLabel(String modifiedBy, HomeTrade? trade) {
  final by = modifiedBy.trim();
  final name = trade?.analystName?.trim() ?? '';
  if (name.isEmpty) return by.isEmpty ? '—' : by;
  if (by.isEmpty) return name;

  final id = (trade?.analystId ?? '').trim();
  final upper = by.toUpperCase();
  final looksLikeId = by == id ||
      upper.startsWith('ANALYST_') ||
      upper.startsWith('USER_');
  return looksLikeId ? name : by;
}

String _formatModifiedTargets(dynamic value) {
  if (value is! List || value.isEmpty) return '—';

  return value.asMap().entries.map((entry) {
    final dynamic rawTarget = entry.value;
    if (rawTarget is! Map) return 'T${entry.key + 1}: —';

    final dynamic priceRaw =
        rawTarget['target_price'] ?? rawTarget['price'] ?? rawTarget['target'];
    final dynamic percentRaw =
        rawTarget['book_percent'] ?? rawTarget['bookPercent'];
    final double? price = priceRaw is num
        ? priceRaw.toDouble()
        : double.tryParse(priceRaw?.toString() ?? '');
    final double? percent = percentRaw is num
        ? percentRaw.toDouble()
        : double.tryParse(percentRaw?.toString() ?? '');

    final String priceText = price == null ? '—' : _money(price);
    final String percentText =
        percent == null ? '—' : '${percent.toStringAsFixed(0)}%';
    return 'T${entry.key + 1}: $priceText\nBook percent: $percentText';
  }).join('\n\n');
}

String _formatModificationValue(String field, dynamic value) {
  if (value == null) return '—';
  if (field.toLowerCase() == 'targets') {
    return _formatModifiedTargets(value);
  }

  const Set<String> priceFields = <String>{
    'target',
    'target_price',
    'entry',
    'entry_price',
    'sl',
    'stop_loss',
  };
  if (priceFields.contains(field.toLowerCase())) {
    final double? price = value is num
        ? value.toDouble()
        : double.tryParse(value.toString());
    if (price != null) return _money(price);
  }

  return value.toString();
}

String _formatDate(DateTime? dt) {
  if (dt == null) return '—';
  return DateFormat('dd MMM yyyy, h:mm a').format(dt.toLocal());
}

class TradeDetailsPage extends StatefulWidget {
  const TradeDetailsPage({super.key, this.trade, this.tradeId});

  final HomeTrade? trade;

  /// Used when opening from FCM / deep link without a full [HomeTrade].
  final String? tradeId;

  @override
  State<TradeDetailsPage> createState() => _TradeDetailsPageState();
}

class _TradeDetailsPageState extends State<TradeDetailsPage> {
  StreamSubscription<Map<String, double>>? _pricesSubscription;
  StreamSubscription<WsTradeEvent>? _tradeWsSubscription;
  late HomeTrade? _trade;
  bool _isLoadingDetails = false;

  String? get _resolvedTradeId {
    final fromTrade = _trade?.id.trim();
    if (fromTrade != null && fromTrade.isNotEmpty) return fromTrade;
    final fromQuery = widget.tradeId?.trim();
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _trade = widget.trade;
    final LivePricesService livePrices = getIt<LivePricesService>();
    livePrices.start();
    livePrices.trackAdditional(<String>[widget.trade?.symbol ?? '']);
    _applyLivePrices(livePrices.current);
    _pricesSubscription = livePrices.pricesStream.listen(_applyLivePrices);
    _tradeWsSubscription =
        getIt<WebSocketService>().tradeEvents.listen(_onWsTradeEvent);
    unawaited(getIt<WebSocketService>().connect());
    _loadTradeDetails();
  }

  @override
  void didUpdateWidget(covariant TradeDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trade?.id != widget.trade?.id ||
        oldWidget.tradeId != widget.tradeId) {
      _trade = widget.trade;
      final LivePricesService livePrices = getIt<LivePricesService>();
      livePrices.trackAdditional(<String>[widget.trade?.symbol ?? '']);
      _applyLivePrices(livePrices.current);
      _loadTradeDetails();
    }
  }

  Future<void> _loadTradeDetails() async {
    final String? tradeId = _resolvedTradeId;
    if (tradeId == null || tradeId.isEmpty) return;

    setState(() => _isLoadingDetails = true);
    try {
      final HomeTrade trade =
          await getIt<HomeRepository>().fetchTrade(tradeId);
      if (!mounted) return;
      if (_trade != null && _trade!.id != tradeId) return;

      final LivePricesService livePrices = getIt<LivePricesService>();
      setState(() {
        _trade = trade;
        _isLoadingDetails = false;
      });
      livePrices.trackAdditional(<String>[trade.symbol]);
      _applyLivePrices(livePrices.current);
    } catch (_) {
      if (mounted && (_trade == null || _trade!.id == tradeId)) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  void _applyLivePrices(Map<String, double> prices) {
    final HomeTrade? trade = _trade;
    if (trade == null || prices.isEmpty) return;

    double? price = prices[trade.symbol];
    price ??= prices[trade.symbol.split(' / ').first.trim()];
    if (price == null || price == trade.ltp || !mounted) return;

    setState(() => _trade = trade.copyWith(ltp: price));
  }

  void _onWsTradeEvent(WsTradeEvent event) {
    final tradeId = _resolvedTradeId;
    if (tradeId == null || event.tradeId != tradeId) return;
    final current = _trade;
    if (current == null && event.kind != WsTradeEventKind.created) {
      return;
    }

    switch (event.kind) {
      case WsTradeEventKind.modified:
        if (current == null) {
          unawaited(_loadTradeDetails());
          return;
        }
        final patched = WsTradeMerge.applyModified(current, event.payload);
        if (patched.sl == current.sl &&
            patched.t1 == current.t1 &&
            patched.t2 == current.t2 &&
            patched.t3 == current.t3) {
          unawaited(_loadTradeDetails());
          return;
        }
        setState(() => _trade = patched);
      case WsTradeEventKind.closed:
        if (current == null) return;
        setState(
          () => _trade = WsTradeMerge.applyClosed(current, event.payload),
        );
      case WsTradeEventKind.created:
        break;
      case WsTradeEventKind.unknown:
        break;
    }
  }

  @override
  void dispose() {
    _pricesSubscription?.cancel();
    _tradeWsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _trade;

    // Fallback values when no trade passed
    final symbol = t?.symbol ?? '—';
    final company = t?.companyName ?? t?.symbol ?? '—';
    final isClosed = t != null && !t.state.isLive;

    final currentPrice = isClosed
        ? (t?.exitPrice ?? t?.ltp ?? t?.entry ?? 0)
        : (t?.ltp ?? t?.entry ?? 0);
    final exitPriceStr =
        t?.exitPrice != null ? _money(t!.exitPrice!) : '—';
    final pnl = t == null
        ? null
        : t.state == HomeTradeState.live
            ? (t.ltpPnlPercent ?? t.currentPnlPercent)
            : t.currentPnlPercent;
    final isProfit = (pnl ?? 0) >= 0;
    final changeColor = isProfit ? ColorConstants.green : ColorConstants.red;
    final pnlText = _signedPct(pnl);

    final direction = t?.direction == HomeTradeDirection.short ? 'SHORT' : 'LONG';
    final directionColor = t?.direction == HomeTradeDirection.short
        ? ColorConstants.red
        : ColorConstants.green;

    final statusLabel = t == null
        ? '—'
        : t.state == HomeTradeState.live && pnl != null
            ? pnl > 0
                ? 'In profit'
                : pnl < 0
                    ? 'In loss'
                    : 'At cost'
            : t.statusLabel;
    final isLoss = statusLabel.toLowerCase().contains('loss') ||
        statusLabel.toLowerCase().contains('sl');
    final statusColor = isLoss ? ColorConstants.red : ColorConstants.green;
    final useLossBackground = isClosed ||
        isLoss ||
        (pnl != null && pnl < 0);
    final useProfitBackground = !useLossBackground &&
        ((pnl != null && pnl > 0) ||
            t?.state == HomeTradeState.allTargetsHit);

    final entryStr = _money(t?.entry ?? 0);
    final slStr = _money(t?.sl ?? 0);
    final riskRewardRatio = _riskRewardRatio(t);
    final estimatedGain =
        t != null ? _signedPct(t.estimatedGainPercent) : '—';
    final estimatedRisk = t != null && t.entry != 0
        ? _signedPct(((t.sl - t.entry) / t.entry) * 100)
        : '—';

    final batchName = t?.batchName ?? '—';
    final analystName = t?.analystName ?? '—';
    final analystAvatarUrl = t?.analystAvatarUrl;
    final analystWinRate = t?.analystWinRate;
    final entryDateTime = _formatDate(t?.entryTimestamp ?? t?.nseTimestamp);
    final exitDateTime = _formatDate(t?.exitTimestamp);
    final nseTimestamp = _formatDate(t?.nseTimestamp);
    final rationale = t?.rationale;
    final modifications = t?.modifications ?? <TradeModification>[];
    final DateTime? lastModifiedRaw = modifications.isNotEmpty
        ? modifications
            .map((m) => m.modifiedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b)
        : (t?.exitTimestamp ?? t?.entryTimestamp);
    final lastModifiedDateTime = _formatDate(lastModifiedRaw);
    final allTargets = t?.targets ?? <TradeTarget>[];

    return Scaffold(
      backgroundColor: ColorConstants.pageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (useProfitBackground || useLossBackground)
            _TradeDetailsBackground(isLoss: useLossBackground)
          else
            const AppScreenBackground(),
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding:
                      AppSize.insets(context, left: 16, right: 16, top: 8,bottom: 8),
                  child: AppBackHeader(
                    title:
                        isClosed ? 'Closed trade details' : 'Live trade details',
                    onBack: () => context.pop(),
                    trailing: _TradeSaveButton(
                      tradeId: t?.id,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSize.insets(
                      context,
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // ── Symbol header card ──────────────────────────────
                        _SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  TradeSymbolAvatar(
                                    symbol: symbol,
                                    companyName: t?.companyName,
                                    logoUrl: t?.logoUrl,
                                    size: AppSize.r(context, 48),
                                    circular: false,
                                    borderRadius: AppSize.r(context, 14),
                                  ),
                                  SizedBox(width: AppSize.w(context, 12)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: AppSize.w(context, 8),
                                          runSpacing: AppSize.h(context, 4),
                                          children: <Widget>[
                                            Text(
                                              symbol,
                                              style: TextStyleConstants
                                                  .cardTitle
                                                  .copyWith(
                                                fontSize:
                                                    AppSize.sp(context, 16),
                                              ),
                                            ),
                                            _ExchangePill(
                                              label: t?.segmentLabel ?? 'NSE',
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: AppSize.h(context, 2)),
                                        Text(
                                          company,
                                          style: TextStyleConstants.caption
                                              .copyWith(
                                            fontSize: AppSize.sp(context, 12),
                                            color: ColorConstants.mute,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      Text(
                                        _money(currentPrice),
                                        style: TextStyleConstants.numeric
                                            .copyWith(
                                          fontSize: AppSize.sp(context, 16),
                                          fontWeight: FontWeight.w700,
                                          color: ColorConstants.ink,
                                        ),
                                      ),
                                      SizedBox(height: AppSize.h(context, 2)),
                                      Text(
                                        pnlText,
                                        style: TextStyleConstants.caption
                                            .copyWith(
                                          fontSize: AppSize.sp(context, 11),
                                          fontWeight: FontWeight.w600,
                                          color: changeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: AppSize.h(context, 16)),
                              if (!isClosed) ...<Widget>[
                                TradeSignalTimeline(
                                  timestamp: _formatDate(
                                      t?.entryTimestamp ?? t?.nseTimestamp),
                                  entry: entryStr,
                                  stopLoss: slStr,
                                  target: _money(t?.finalTarget ?? 0),
                                  currentPrice: _money(currentPrice),
                                ),
                                const TaperedHorizontalDivider(
                                  verticalPadding: 12,
                                ),
                              ],
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _LabeledValue(
                                      label: 'Entry',
                                      value: entryStr,
                                    ),
                                  ),
                                  const TaperedVerticalDivider(height: 44),
                                  Expanded(
                                    child: _LabeledValue(
                                      label: 'Stop loss',
                                      value: slStr,
                                      valueColor: ColorConstants.red,
                                      alignEnd: true,
                                    ),
                                  ),
                                ],
                              ),
                              const TaperedHorizontalDivider(
                                verticalPadding: 12,
                              ),
                              _TargetsSummary(
                                targets: allTargets,
                                fallbackTarget: t?.finalTarget,
                              ),
                              const TaperedHorizontalDivider(
                                verticalPadding: 16,
                              ),

                        // ── Trade info card ─────────────────────────────────
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: _LabeledValue(
                                      label: 'Direction',
                                      value: direction,
                                      valueColor: directionColor,
                                    ),
                                  ),
                                  const TaperedVerticalDivider(height: 44),
                                  Expanded(
                                    child: _LabeledValue(
                                      label: 'Segment',
                                      value: t?.segmentLabel ?? '—',
                                      alignCenter: true,
                                    ),
                                  ),
                                  const TaperedVerticalDivider(height: 44),
                                  Expanded(
                                    child: _LabeledValue(
                                      label: 'Category',
                                      value: t?.categoryLabel ?? '—',
                                      alignEnd: true,
                                    ),
                                  ),
                                ],
                              ),
                              const TaperedHorizontalDivider(
                                  verticalPadding: 12),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _LabeledValue(
                                      label: isClosed
                                          ? 'Final returns'
                                          : 'Estimated gains',
                                      value: isClosed
                                          ? pnlText
                                          : estimatedGain,
                                      valueColor: isClosed
                                          ? changeColor
                                          : ColorConstants.green,
                                    ),
                                  ),
                                  const TaperedVerticalDivider(height: 44),
                                  Expanded(
                                    child: _LabeledValue(
                                      label: isClosed
                                          ? 'Exit price'
                                          : 'Live return',
                                      value: isClosed
                                          ? exitPriceStr
                                          : pnlText,
                                      valueColor: isClosed
                                          ? ColorConstants.ink
                                          : changeColor,
                                      alignEnd: true,
                                    ),
                                  ),
                                ],
                              ),
                              const TaperedHorizontalDivider(
                                  verticalPadding: 12),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _LabeledValue(
                                      label: 'Estimated risk',
                                      value: estimatedRisk,
                                      valueColor: ColorConstants.red,
                                    ),
                                  ),
                                  const TaperedVerticalDivider(height: 44),
                                  Expanded(
                                    child: _LabeledValue(
                                      label: 'Risk : reward',
                                      value: riskRewardRatio,
                                      valueColor: ColorConstants.brandBlue,
                                      alignEnd: true,
                                    ),
                                  ),
                                ],
                              ),
                              const TaperedHorizontalDivider(
                                  verticalPadding: 12),
                              _DetailRow(
                                label: 'Entry date & time',
                                value: entryDateTime,
                              ),
                              if (isClosed) ...<Widget>[
                                const TaperedHorizontalDivider(
                                    verticalPadding: 10),
                                _DetailRow(
                                  label: 'Exit date & time',
                                  value: exitDateTime,
                                ),
                                const TaperedHorizontalDivider(
                                    verticalPadding: 10),
                                _DetailRow(
                                  label: 'Exit price',
                                  value: exitPriceStr,
                                  valueColor: ColorConstants.ink,
                                ),
                                const TaperedHorizontalDivider(
                                    verticalPadding: 10),
                                _DetailRow(
                                  label: 'Last modified',
                                  value: lastModifiedDateTime,
                                ),
                              ],
                              const TaperedHorizontalDivider(
                                  verticalPadding: 10),
                              _DetailRow(
                                label: 'Status',
                                value: statusLabel,
                                valueColor: statusColor,
                              ),
                              if (!isClosed) ...<Widget>[
                                const TaperedHorizontalDivider(
                                    verticalPadding: 10),
                                _DetailRow(
                                    label: 'Batch', value: batchName),
                              ],
                              const TaperedHorizontalDivider(
                                  verticalPadding: 10),
                              _DetailRow(
                                label: 'NSE timestamp',
                                value: nseTimestamp,
                              ),
                              if (rationale != null &&
                                  rationale.isNotEmpty) ...<Widget>[
                                const TaperedHorizontalDivider(
                                    verticalPadding: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Rationale',
                                    style: TextStyleConstants.caption
                                        .copyWith(
                                      fontSize: AppSize.sp(context, 11),
                                      fontWeight: FontWeight.w600,
                                      color: ColorConstants.mute,
                                    ),
                                  ),
                                ),
                                SizedBox(height: AppSize.h(context, 6)),
                                Text(
                                  rationale,
                                  style:
                                      TextStyleConstants.bodyMedium.copyWith(
                                    fontSize: AppSize.sp(context, 13),
                                    height: 1.45,
                                    color: ColorConstants.ink
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 20)),

                        // ── Actions (modification history) ──────────────────
                        Text(
                          'Actions',
                          style: TextStyleConstants.cardTitle.copyWith(
                            fontSize: AppSize.sp(context, 16),
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 4)),
                        Text(
                          _isLoadingDetails
                              ? 'Loading actions...'
                              : modifications.isEmpty
                                  ? (t?.state ==
                                          HomeTradeState.manuallyClosed
                                      ? 'This trade was manually closed.'
                                      : 'No actions on this trade yet.')
                                  : 'This trade has been modified.',
                          style: TextStyleConstants.caption.copyWith(
                            fontSize: AppSize.sp(context, 12),
                            fontStyle: FontStyle.italic,
                            color: ColorConstants.mute,
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 10)),
                        if (t?.state == HomeTradeState.manuallyClosed &&
                            modifications.isEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: AppSize.h(context, 10),
                            ),
                            child: _SurfaceCard(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: <Widget>[
                                  _DetailRow(
                                    label: 'Action',
                                    value: 'Manually closed',
                                    valueColor: ColorConstants.green,
                                  ),
                                  if (t?.entryTimestamp != null) ...<Widget>[
                                    const TaperedHorizontalDivider(
                                      verticalPadding: 10,
                                    ),
                                    _DetailRow(
                                      label: 'Entry date & time',
                                      value: _formatDate(t!.entryTimestamp),
                                    ),
                                  ],
                                  if (t?.exitTimestamp != null) ...<Widget>[
                                    const TaperedHorizontalDivider(
                                      verticalPadding: 10,
                                    ),
                                    _DetailRow(
                                      label: 'Exit date & time',
                                      value: _formatDate(t!.exitTimestamp),
                                    ),
                                  ],
                                  if (lastModifiedRaw != null) ...<Widget>[
                                    const TaperedHorizontalDivider(
                                      verticalPadding: 10,
                                    ),
                                    _DetailRow(
                                      label: 'Last modified',
                                      value: lastModifiedDateTime,
                                    ),
                                  ],
                                  if (t != null) ...<Widget>[
                                    const TaperedHorizontalDivider(
                                      verticalPadding: 10,
                                    ),
                                    _DetailRow(
                                      label: 'NSE timestamp',
                                      value: _formatDate(t.nseTimestamp),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ...modifications.map(
                          (mod) => Padding(
                            padding: EdgeInsets.only(
                                bottom: AppSize.h(context, 10)),
                            child: _SurfaceCard(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: <Widget>[
                                  _DetailRow(
                                    label: 'Modified at',
                                    value: _formatDate(mod.modifiedAt),
                                  ),
                                  const TaperedHorizontalDivider(
                                      verticalPadding: 10),
                                  _DetailRow(
                                    label: 'Modified by',
                                    value: _modificationAuthorLabel(
                                      mod.modifiedBy,
                                      t,
                                    ),
                                  ),
                                  if (mod.reason.isNotEmpty) ...<Widget>[
                                    const TaperedHorizontalDivider(
                                        verticalPadding: 10),
                                    _DetailRow(
                                      label: 'Reason',
                                      value: mod.reason,
                                    ),
                                  ],
                                  ...mod.fieldsChanged.entries.map((e) {
                                    final field = e.key;
                                    final change = e.value as Map?;
                                    final formattedOld =
                                        _formatModificationValue(
                                      field,
                                      change?['old'],
                                    );
                                    final formattedNew =
                                        _formatModificationValue(
                                      field,
                                      change?['new'],
                                    );
                                    final bool useComparisonUi =
                                        _usesModificationComparison(field);
                                    return Column(
                                      children: <Widget>[
                                        const TaperedHorizontalDivider(
                                            verticalPadding: 10),
                                        if (useComparisonUi)
                                          _FieldModificationComparison(
                                            label: _modificationFieldLabel(
                                              field,
                                            ),
                                            before: formattedOld,
                                            after: formattedNew,
                                          )
                                        else
                                          _DetailRow(
                                            label:
                                                _modificationFieldLabel(field),
                                            value:
                                                '$formattedOld → $formattedNew',
                                          ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── Analyst profile card ────────────────────────────
                        SizedBox(height: AppSize.h(context, 10)),
                        Text(
                          'Profile data',
                          style: TextStyleConstants.cardTitle.copyWith(
                            fontSize: AppSize.sp(context, 16),
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 10)),
                        _SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  _AdvisorTagChip(
                                    label: t?.categoryLabel ?? '—',
                                  ),
                                  SizedBox(width: AppSize.w(context, 10)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: AppSize.w(context, 6),
                                          runSpacing: AppSize.h(context, 4),
                                          children: <Widget>[
                                            Text(
                                              analystName,
                                              style: TextStyleConstants
                                                  .cardTitle
                                                  .copyWith(
                                                fontSize:
                                                    AppSize.sp(context, 15),
                                              ),
                                            ),
                                            const SebiVerifiedPill(
                                                compact: true),
                                          ],
                                        ),
                                        if (analystWinRate != null) ...<Widget>[
                                          SizedBox(
                                              height: AppSize.h(context, 4)),
                                          Text(
                                            'Win rate: ${analystWinRate.toStringAsFixed(1)}%',
                                            style: TextStyleConstants.caption
                                                .copyWith(
                                              fontSize:
                                                  AppSize.sp(context, 11),
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  ColorConstants.brandBlue,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: AppSize.h(context, 14)),
                              CommonButtonWidget(
                                label: 'View profile',
                                height: 44,
                                borderRadius: 10,
                                backgroundColor: ColorConstants.white,
                                foregroundColor: ColorConstants.brandBlue,
                                borderColor: ColorConstants.brandBlue,
                                onPressed: () {
                                  final analystId = t?.analystId?.trim();
                                  if (analystId == null || analystId.isEmpty) {
                                    return;
                                  }
                                  context.push(
                                    AppRoutingName.advisorProfile,
                                    extra: analystId,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSize.h(context, 16)),
                        const SebiDisclaimerStrip(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeSaveButton extends StatefulWidget {
  const _TradeSaveButton({required this.tradeId});

  final String? tradeId;

  @override
  State<_TradeSaveButton> createState() => _TradeSaveButtonState();
}

class _TradeSaveButtonState extends State<_TradeSaveButton> {
  bool _isSaved = false;
  bool _isLoading = true;
  bool _isUpdating = false;

  HomeRepository get _repository => getIt<HomeRepository>();

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final String? tradeId = widget.tradeId;
    if (tradeId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final Set<String> savedIds = await _repository.fetchSavedTradeIds();
      if (mounted) {
        setState(() {
          _isSaved = savedIds.contains(tradeId);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSaved() async {
    final String? tradeId = widget.tradeId;
    if (tradeId == null || _isUpdating) return;

    final bool wasSaved = _isSaved;
    setState(() {
      _isSaved = !wasSaved;
      _isUpdating = true;
    });

    try {
      final bool saved = wasSaved
          ? await _repository.unsaveTrade(tradeId)
          : await _repository.saveTrade(tradeId);
      if (!mounted) return;
      setState(() {
        _isSaved = saved;
        _isUpdating = false;
      });
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
        _isSaved = wasSaved;
        _isUpdating = false;
      });
      await CommonAppNotificationBar.error(
        context: context,
        title: 'Unable to update saved trade',
        message: 'Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _isSaved ? ColorConstants.liveBg : ColorConstants.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        side: BorderSide(
          color:
              _isSaved ? ColorConstants.brandBlue : ColorConstants.line,
        ),
      ),
      child: InkWell(
        onTap: _isLoading || _isUpdating || widget.tradeId == null
            ? null
            : _toggleSaved,
        borderRadius: BorderRadius.circular(AppSize.r(context, 12)),
        child: SizedBox(
          width: AppSize.r(context, 40),
          height: AppSize.r(context, 40),
          child: Center(
            child: _isLoading || _isUpdating
                ? SizedBox(
                    width: AppSize.r(context, 17),
                    height: AppSize.r(context, 17),
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    size: AppSize.r(context, 22),
                    color: ColorConstants.brandBlue,
                  ),
          ),
        ),
      ),
    );
  }
}

class _TradeDetailsBackground extends StatelessWidget {
  const _TradeDetailsBackground({required this.isLoss});

  final bool isLoss;

  @override
  Widget build(BuildContext context) {
    final accent = isLoss ? ColorConstants.red : ColorConstants.green;
    final background =
        isLoss ? ColorConstants.lossBg : ColorConstants.profitBg;
    final Color borderTint = Color.lerp(
      ColorConstants.white,
      background,
      0.72,
    )!;
    final Color outcomeTint = Color.lerp(
      ColorConstants.pageBackground,
      accent,
      0.13,
    )!;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const <double>[0, 0.46, 1],
                colors: <Color>[
                  borderTint,
                  ColorConstants.pageBackground,
                  outcomeTint,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.9, -0.85),
                radius: 0.95,
                colors: <Color>[
                  accent.withValues(alpha: 0.12),
                  background.withValues(alpha: 0.16),
                  ColorConstants.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          AppSize.insets(context, left: 14, right: 14, top: 14, bottom: 14),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 16)),
        border: Border.all(
          color: ColorConstants.navy.withValues(alpha: 0.06),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: ColorConstants.navy.withValues(alpha: 0.05),
            blurRadius: AppSize.r(context, 16),
            offset: Offset(0, AppSize.h(context, 4)),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AdvisorTagChip extends StatelessWidget {
  const _AdvisorTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSize.r(context, 52),
      height: AppSize.r(context, 52),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ColorConstants.liveBg,
        borderRadius: BorderRadius.circular(AppSize.r(context, 10)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyleConstants.caption.copyWith(
          fontSize: AppSize.sp(context, 9),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: ColorConstants.brandBlue,
        ),
      ),
    );
  }
}

class _ExchangePill extends StatelessWidget {
  const _ExchangePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSize.symmetric(context, horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ColorConstants.liveBg,
        borderRadius: BorderRadius.circular(AppSize.r(context, 6)),
        border: Border.all(
          color: ColorConstants.brandBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyleConstants.caption.copyWith(
          fontSize: AppSize.sp(context, 10),
          fontWeight: FontWeight.w700,
          color: ColorConstants.brandBlue,
        ),
      ),
    );
  }
}

class _TargetsSummary extends StatelessWidget {
  const _TargetsSummary({
    required this.targets,
    required this.fallbackTarget,
  });

  final List<TradeTarget> targets;
  final double? fallbackTarget;

  @override
  Widget build(BuildContext context) {
    final List<TradeTarget> visibleTargets = targets.isNotEmpty
        ? targets
        : fallbackTarget == null
            ? const <TradeTarget>[]
            : <TradeTarget>[
                TradeTarget(price: fallbackTarget!, bookPercent: 100),
              ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          visibleTargets.length > 1 ? 'Targets' : 'Target',
          style: TextStyleConstants.caption.copyWith(
            fontSize: AppSize.sp(context, 11),
            fontWeight: FontWeight.w600,
            color: ColorConstants.mute,
          ),
        ),
        SizedBox(height: AppSize.h(context, 8)),
        if (visibleTargets.isEmpty)
          Text(
            '—',
            style: TextStyleConstants.numeric.copyWith(
              fontSize: AppSize.sp(context, 14),
              fontWeight: FontWeight.w700,
              color: ColorConstants.ink,
            ),
          )
        else
          Wrap(
            spacing: AppSize.w(context, 8),
            runSpacing: AppSize.h(context, 8),
            children: visibleTargets.asMap().entries.map((entry) {
              final TradeTarget target = entry.value;
              final String label = visibleTargets.length == 1
                  ? 'Target'
                  : 'T${entry.key + 1}';
              return Container(
                padding: AppSize.symmetric(
                  context,
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: ColorConstants.profitBg.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(AppSize.r(context, 9)),
                  border: Border.all(
                    color: ColorConstants.green.withValues(alpha: 0.20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '$label  ',
                          style: TextStyleConstants.caption.copyWith(
                            fontSize: AppSize.sp(context, 10),
                            fontWeight: FontWeight.w700,
                            color: ColorConstants.green,
                          ),
                        ),
                        Text(
                          _money(target.price),
                          style: TextStyleConstants.numeric.copyWith(
                            fontSize: AppSize.sp(context, 12),
                            fontWeight: FontWeight.w700,
                            color: ColorConstants.ink,
                          ),
                        ),
                      ],
                    ),
                    if (visibleTargets.length > 1) ...<Widget>[
                      SizedBox(height: AppSize.h(context, 4)),
                      Text(
                        'Book percent: ${target.bookPercent.toInt()}%',
                        style: TextStyleConstants.caption.copyWith(
                          fontSize: AppSize.sp(context, 9),
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.mute,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({
    required this.label,
    required this.value,
    this.valueColor = ColorConstants.ink,
    this.alignEnd = false,
    this.alignCenter = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;
  final bool alignCenter;

  CrossAxisAlignment get _cross {
    if (alignEnd) return CrossAxisAlignment.end;
    if (alignCenter) return CrossAxisAlignment.center;
    return CrossAxisAlignment.start;
  }

  TextAlign get _align {
    if (alignEnd) return TextAlign.right;
    if (alignCenter) return TextAlign.center;
    return TextAlign.left;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: _cross,
      children: <Widget>[
        Text(
          label,
          textAlign: _align,
          style: TextStyleConstants.caption.copyWith(
            fontSize: AppSize.sp(context, 11),
            fontWeight: FontWeight.w500,
            color: ColorConstants.mute,
          ),
        ),
        SizedBox(height: AppSize.h(context, 4)),
        Text(
          value,
          textAlign: _align,
          style: TextStyleConstants.numeric.copyWith(
            fontSize: AppSize.sp(context, 14),
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _FieldModificationComparison extends StatelessWidget {
  const _FieldModificationComparison({
    required this.label,
    required this.before,
    required this.after,
  });

  final String label;
  final String before;
  final String after;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyleConstants.caption.copyWith(
            fontSize: AppSize.sp(context, 12),
            color: ColorConstants.mute,
          ),
        ),
        SizedBox(height: AppSize.h(context, 8)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _ModificationChangeColumn(
                title: 'Before',
                value: before,
                background: ColorConstants.gray50,
                accent: ColorConstants.mute,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w(context, 7),
                vertical: AppSize.h(context, 24),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: AppSize.r(context, 17),
                color: ColorConstants.brandBlue,
              ),
            ),
            Expanded(
              child: _ModificationChangeColumn(
                title: 'After',
                value: after,
                background:
                    ColorConstants.liveBg.withValues(alpha: 0.72),
                accent: ColorConstants.brandBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModificationChangeColumn extends StatelessWidget {
  const _ModificationChangeColumn({
    required this.title,
    required this.value,
    required this.background,
    required this.accent,
  });

  final String title;
  final String value;
  final Color background;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSize.insets(
        context,
        left: 9,
        right: 9,
        top: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSize.r(context, 9)),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyleConstants.caption.copyWith(
              fontSize: AppSize.sp(context, 10),
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          SizedBox(height: AppSize.h(context, 5)),
          Text(
            value,
            style: TextStyleConstants.bodyMedium.copyWith(
              fontSize: AppSize.sp(context, 10.5),
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: ColorConstants.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor = ColorConstants.navy,
    this.valueMono = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool valueMono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyleConstants.caption.copyWith(
              fontSize: AppSize.sp(context, 12),
              color: ColorConstants.mute,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: (valueMono
                    ? TextStyleConstants.caption
                    : TextStyleConstants.bodyMedium)
                .copyWith(
              fontSize: AppSize.sp(context, 12),
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: valueMono
                  ? const <FontFeature>[FontFeature.tabularFigures()]
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
