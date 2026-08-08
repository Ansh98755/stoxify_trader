import 'dart:ui';

import '../../core/constants/color_constants.dart';

enum TradeDir {
  short,
  long;

  static TradeDir fromString(String? v) {
    if (v == null) return TradeDir.long;
    final s = v.toUpperCase();
    return s == 'SHORT' ? TradeDir.short : TradeDir.long;
  }
}

class TradingCardData {
  const TradingCardData({
    required this.symbol,
    this.tradeId,
    this.dir,
    this.company,
    this.batchName,
    this.currentPrice,
    this.cmp,
    this.change,
    this.tradeStatus,
    this.isLive = true,
    this.exitPrice,
    this.exitAt,
    this.entry,
    this.analystName,
    this.logoUrl,
    this.sl,
    this.target,
    this.estGain,
    this.liveRet,
    this.segment,
    this.asset,
    this.isSaved = false,
    this.isSaving = false,
    this.onSaveTap,
    this.showLongSignal = false,
    this.rationale,
    this.compact = false,
  });

  final String symbol;
  final String? tradeId;
  final TradeDir? dir;

  final String? company;
  final String? batchName;
  final String? currentPrice;
  final String? cmp;
  final String? change;
  final bool isSaved;
  /// True while a save/unsave API call is in flight for this card.
  final bool isSaving;
  final VoidCallback? onSaveTap;
  final String? analystName;
  final String? logoUrl;

  final String? tradeStatus;
  /// True while the trade is still open (LIVE / T1 / T2); false when closed.
  final bool isLive;
  /// Formatted exit price for closed trades (replaces LTP on the card).
  final String? exitPrice;
  /// Formatted exit date & time for closed trades.
  final String? exitAt;
  final bool showLongSignal;
  final String? entry;
  final String? sl;
  final String? target;

  final String? estGain;
  final String? liveRet;

  final String? segment;
  final String? asset;
  final String? rationale;

  final bool compact;

  TradingCardData copyWith({
    String? symbol,
    String? tradeId,
    TradeDir? dir,
    String? company,
    String? batchName,
    String? currentPrice,
    String? cmp,
    String? change,
    String? tradeStatus,
    bool? isLive,
    String? exitPrice,
    String? exitAt,
    String? entry,
    String? analystName,
    String? logoUrl,
    String? sl,
    String? target,
    String? estGain,
    String? liveRet,
    String? segment,
    String? asset,
    String? rationale,
    bool? isSaved,
    bool? isSaving,
    VoidCallback? onSaveTap,
    bool? showLongSignal,
    bool? compact,
  }) {
    return TradingCardData(
      symbol: symbol ?? this.symbol,
      tradeId: tradeId ?? this.tradeId,
      dir: dir ?? this.dir,
      company: company ?? this.company,
      batchName: batchName ?? this.batchName,
      currentPrice: currentPrice ?? this.currentPrice,
      cmp: cmp ?? this.cmp,
      change: change ?? this.change,
      tradeStatus: tradeStatus ?? this.tradeStatus,
      isLive: isLive ?? this.isLive,
      exitPrice: exitPrice ?? this.exitPrice,
      exitAt: exitAt ?? this.exitAt,
      entry: entry ?? this.entry,
      analystName: analystName ?? this.analystName,
      logoUrl: logoUrl ?? this.logoUrl,
      sl: sl ?? this.sl,
      target: target ?? this.target,
      estGain: estGain ?? this.estGain,
      liveRet: liveRet ?? this.liveRet,
      segment: segment ?? this.segment,
      asset: asset ?? this.asset,
      rationale: rationale ?? this.rationale,
      isSaved: isSaved ?? this.isSaved,
      isSaving: isSaving ?? this.isSaving,
      onSaveTap: onSaveTap ?? this.onSaveTap,
      showLongSignal: showLongSignal ?? this.showLongSignal,
      compact: compact ?? this.compact,
    );
  }
}

bool resolveTradingCardIsLoss(TradingCardData data) {
  final String? status = data.tradeStatus?.toLowerCase();
  if (status != null && status.isNotEmpty) {
    if (status.contains('loss')) return true;
    if (status.contains('profit')) return false;
  }

  for (final String? raw in <String?>[data.estGain, data.liveRet, data.change]) {
    if (raw == null || raw.trim().isEmpty) continue;
    final String t = raw.trim();
    if (t.startsWith('-') || t.startsWith('−')) return true;
    if (t.startsWith('+')) return false;
  }

  return data.dir == TradeDir.short;
}

Color tradingCardThemeColor(bool isLoss) =>
    isLoss ? ColorConstants.red : ColorConstants.green;

Color tradingCardBorderColor(bool isLoss) =>
    isLoss ? ColorConstants.lossBg : ColorConstants.profitBg;

Color metricValueColor(String value, {required bool themeIsLoss}) {
  final String t = value.trim();
  if (t.startsWith('-') || t.startsWith('−')) return ColorConstants.red;
  if (t.startsWith('+')) return ColorConstants.green;
  final lower = t.toLowerCase();
  if (lower.contains('loss')) return ColorConstants.red;
  if (lower.contains('profit')) return ColorConstants.green;
  return tradingCardThemeColor(themeIsLoss);
}
