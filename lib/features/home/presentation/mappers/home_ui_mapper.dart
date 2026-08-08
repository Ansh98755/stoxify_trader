import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/models/trading_card_data.dart';
// import '../../../../core/widgets/common_trading_card.dart';
import '../../domain/entities/home_subscription.dart';
import '../../domain/entities/home_trade.dart';
import '../widgets/home_subscriptions_strip.dart';

final NumberFormat _inr = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

final NumberFormat _inrPrecise = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

String _money(double value, {bool precise = false}) {
  final abs = value.abs();
  final formatted =
      (precise || abs < 100) ? _inrPrecise.format(value) : _inr.format(value);
  return formatted;
}

String _signedPct(double? value, {int digits = 2}) {
  if (value == null) return '—';
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(digits)}%';
}

String _changeLine(HomeTrade trade) {
  final ltp = trade.ltp;
  final entry = trade.entry;
  if (ltp == null || entry == 0) {
    final pnl = trade.currentPnlPercent;
    return pnl == null ? '—' : _signedPct(pnl);
  }
  final delta = trade.direction == HomeTradeDirection.long
      ? (ltp - entry)
      : (entry - ltp);
  final pct = (delta / entry) * 100;
  final sign = delta >= 0 ? '+' : '';
  return '$sign${_money(delta, precise: true)} (${_signedPct(pct)})';
}

String? _exitAtLabel(DateTime? at) {
  if (at == null) return null;
  return DateFormat('dd MMM yyyy · hh:mm a').format(at);
}

/// Maps API [HomeTrade] → UI [TradingCardData] for [CommonTradingCard].
TradingCardData mapHomeTradeToCard(
  HomeTrade trade, {
  Set<String> savedIds = const <String>{},
  VoidCallback? onSaveTap,
  bool isSaving = false,
}) {
  final bool live = trade.state.isLive;
  return TradingCardData(
    symbol: trade.symbol,
    tradeId: trade.id,
    dir: trade.direction == HomeTradeDirection.short
        ? TradeDir.short
        : TradeDir.long,
    company: trade.companyName,
    batchName: trade.batchName,
    showLongSignal: true,
    currentPrice: live
        ? (trade.ltp != null
            ? _money(trade.ltp!, precise: true)
            : _money(trade.entry, precise: true))
        : null,
    change: live ? _changeLine(trade) : null,
    tradeStatus: trade.statusLabel,
    isLive: live,
    exitPrice: !live && trade.exitPrice != null
        ? _money(trade.exitPrice!, precise: true)
        : null,
    exitAt: !live ? _exitAtLabel(trade.exitTimestamp) : null,
    entry: _money(trade.entry, precise: true),
    analystName: trade.analystName,
    logoUrl: trade.logoUrl,
    sl: _money(trade.sl, precise: true),
    target: _money(trade.finalTarget, precise: true),
    estGain: _signedPct(trade.estimatedGainPercent),
    liveRet: _signedPct(trade.currentPnlPercent),
    segment: trade.categoryLabel,
    asset: trade.segmentLabel,
    rationale: trade.rationale,
    isSaved: savedIds.contains(trade.id),
    isSaving: isSaving,
    onSaveTap: onSaveTap,
  );
}

HomeSubscriptionItem mapHomeSubscriptionToItem(HomeSubscription sub) {
  final until = sub.endDate;
  final untilLabel = until == null
      ? (sub.isActive ? 'Active' : sub.status.name)
      : 'Active until ${DateFormat('dd MMM').format(until)}';

  // batchName — what the user subscribed to
  final batch = sub.batchName.trim().isNotEmpty ? sub.batchName.trim() : null;
  // analystName — who runs it (shown as a subtitle under the batch name)
  final analyst = (sub.analystName?.trim().isNotEmpty == true)
      ? sub.analystName!.trim()
      : null;

  return HomeSubscriptionItem(
    id: sub.analystId ?? sub.id,
    initials: sub.initials,
    name: sub.displayName,
    activeUntil: untilLabel,
    batchName: batch,
    analystName: analyst,
  );
}

String? mapFilterSegmentToApi(String segment) {
  switch (segment) {
    case 'Equity':
      return 'EQUITY';
    case 'F&O':
      return 'FNO';
    case 'Commodity':
      return 'COMMODITY';
    default:
      // Intraday/Swing/Long-term are category filters — applied client-side.
      return null;
  }
}

/// Display label for a trade facet value (e.g. EQUITY → Equity).
String formatTradeFacetLabel(String value) {
  final upper = value.trim().toUpperCase();
  switch (upper) {
    case 'FNO':
      return 'F&O';
    case 'EQUITY':
      return 'Equity';
    case 'COMMODITY':
      return 'Commodity';
    case 'LIVE':
      return 'Live';
    case 'CLOSED_BY_TARGET':
      return 'Closed by target';
    case 'CLOSED_BY_SL':
      return 'Closed by SL';
    case 'MANUALLY_CLOSED':
      return 'Manually closed';
    case 'INTRADAY':
      return 'Intraday';
    case 'SWING':
      return 'Swing';
    case 'POSITIONAL':
    case 'LONG_TERM':
      return 'Long-term';
    case 'BTST':
      return 'BTST';
    default:
      return value
          .toLowerCase()
          .split('_')
          .where((part) => part.isNotEmpty)
          .map(
            (part) =>
                '${part[0].toUpperCase()}${part.substring(1)}',
          )
          .join(' ');
  }
}

/// Join multi-selected API facet values for query params (comma-separated).
String? joinFilterValues(Set<String> values) {
  final cleaned = values
      .map((v) => v.trim().toUpperCase())
      .where((v) => v.isNotEmpty && v != 'ALL')
      .toList();
  if (cleaned.isEmpty) return null;
  return cleaned.join(',');
}

/// Feed facet query params for OR semantics across groups.
///
/// Within a group, values are comma-joined (server OR). When more than one
/// group is active (e.g. Equity + Intraday), omit both from the request so the
/// API does not AND them — the client then ORs locally.
({String? segment, String? category}) resolveOrAwareFeedFacets({
  required Set<String> segments,
  required Set<String> categories,
}) {
  final segment = joinFilterValues(segments);
  final category = joinFilterValues(categories);
  if (segment != null && category != null) {
    return (segment: null, category: null);
  }
  return (segment: segment, category: category);
}

/// Default home status when none selected — live recommendations only.
String resolveFeedStatus(Set<String> statuses) {
  final joined = joinFilterValues(statuses);
  return joined ?? 'LIVE';
}

bool isLiveOnlyStatusFilter(Set<String> statuses) {
  if (statuses.isEmpty) return true;
  return statuses.every((s) {
    final upper = s.trim().toUpperCase();
    return upper == 'LIVE' ||
        upper == 'ACTIVE' ||
        upper == 'OPEN' ||
        upper == 'PUBLISHED' ||
        upper == 'RUNNING';
  });
}

