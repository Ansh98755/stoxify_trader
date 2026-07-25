import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/common_trading_card.dart';
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

/// Maps API [HomeTrade] → UI [TradingCardData] for [CommonTradingCard].
TradingCardData mapHomeTradeToCard(
  HomeTrade trade, {
  Set<String> savedIds = const <String>{},
  VoidCallback? onSaveTap,
}) {
  return TradingCardData(
    symbol: trade.symbol,
    tradeId: trade.id,
    dir: trade.direction == HomeTradeDirection.short
        ? TradeDir.short
        : TradeDir.long,
    company: trade.companyName,
    batchName: trade.batchName,
    showLongSignal: true,
    currentPrice: trade.ltp != null
        ? _money(trade.ltp!, precise: true)
        : _money(trade.entry, precise: true),
    change: _changeLine(trade),
    tradeStatus: trade.statusLabel,
    entry: _money(trade.entry, precise: true),
    sl: _money(trade.sl, precise: true),
    target: _money(trade.finalTarget, precise: true),
    estGain: _signedPct(trade.estimatedGainPercent),
    liveRet: _signedPct(trade.currentPnlPercent),
    segment: trade.categoryLabel,
    asset: trade.segmentLabel,
    rationale: trade.rationale,
    isSaved: savedIds.contains(trade.id),
    onSaveTap: onSaveTap,
  );
}

HomeSubscriptionItem mapHomeSubscriptionToItem(HomeSubscription sub) {
  final until = sub.endDate;
  final untilLabel = until == null
      ? (sub.isActive ? 'Active' : sub.status.name)
      : 'Active until ${DateFormat('dd MMM').format(until)}';

  return HomeSubscriptionItem(
    id: sub.id,
    initials: sub.initials,
    name: sub.displayName,
    activeUntil: untilLabel,
  );
}

String? mapFilterSegmentToApi(String segment) {
  switch (segment) {
    case 'Equity':
      return 'EQUITY';
    case 'F&O':
      return 'FNO';
    default:
      // Intraday/Swing/Long-term are category filters — applied client-side.
      return null;
  }
}
