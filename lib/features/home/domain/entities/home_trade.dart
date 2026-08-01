enum HomeTradeDirection { long, short }

enum HomeTradeSegment { equity, fno, commodity }

enum HomeTradeCategory { intraday, swing, positional, btst }

enum HomeTradeState {
  live,
  t1Hit,
  t2Hit,
  allTargetsHit,
  slHit,
  manuallyClosed,
  expired,
}

extension HomeTradeStateX on HomeTradeState {
  bool get isLive =>
      this == HomeTradeState.live ||
      this == HomeTradeState.t1Hit ||
      this == HomeTradeState.t2Hit;
}

/// Domain trade used by Home feed (mapped from `GET /trades/`).
class HomeTrade {
  const HomeTrade({
    required this.id,
    required this.symbol,
    this.companyName,
    required this.direction,
    required this.segment,
    required this.category,
    required this.state,
    required this.entry,
    required this.sl,
    required this.t1,
    this.t2,
    this.t3,
    this.ltp,
    this.pnlPercent,
    this.runningPnlPercent,
    this.batchName,
    this.analystName,
    this.analystAvatarUrl,
    this.analystWinRate,
    this.logoUrl,
    this.rationale,
    required this.nseTimestamp,
    this.entryTimestamp,
    this.targets = const <TradeTarget>[],
    this.hitTargets = const <String>[],
    this.modifications = const <TradeModification>[],
    this.planId,
  });
  final String id;
  final String symbol;
  final String? companyName;
  final HomeTradeDirection direction;
  final HomeTradeSegment segment;
  final HomeTradeCategory category;
  final HomeTradeState state;
  final double entry;
  final double sl;
  final double t1;
  final double? t2;
  final double? t3;
  final double? ltp;
  final double? pnlPercent;
  final double? runningPnlPercent;
  final String? batchName;
  final String? analystName;
  final String? analystAvatarUrl;
  final double? analystWinRate;
  final List<TradeTarget> targets;
  final List<String> hitTargets;
  final DateTime? entryTimestamp;
  final List<TradeModification> modifications;
  final String? planId;
  final String? logoUrl;
  final String? rationale;
  final DateTime nseTimestamp;

  double get finalTarget => t3 ?? t2 ?? t1;

  double? get currentPnlPercent => state.isLive
      ? ltpPnlPercent ?? pnlPercent ?? runningPnlPercent
      : pnlPercent ?? runningPnlPercent;

  double? get ltpPnlPercent {
    final ltpValue = ltp;
    if (ltpValue == null || entry == 0) return null;
    final move = direction == HomeTradeDirection.long
        ? (ltpValue - entry)
        : (entry - ltpValue);
    return move / entry * 100;
  }

  double get estimatedGainPercent {
    if (entry == 0) return 0;
    final move = direction == HomeTradeDirection.long
        ? (finalTarget - entry)
        : (entry - finalTarget);
    return move / entry * 100;
  }

  String get statusLabel {
    switch (state) {
      case HomeTradeState.allTargetsHit:
        return 'Target Hit';
      case HomeTradeState.t1Hit:
        return 'T1 Hit';
      case HomeTradeState.t2Hit:
        return 'T2 Hit';
      case HomeTradeState.slHit:
        return 'Stop Loss Hit';
      case HomeTradeState.manuallyClosed:
        return 'Closed';
      case HomeTradeState.expired:
        return 'Expired';
      case HomeTradeState.live:
        final pnl = currentPnlPercent;
        if (pnl == null || pnl == 0) return 'At cost';
        return pnl > 0 ? 'In profit' : 'In loss';
    }
  }

  String get segmentLabel => switch (segment) {
        HomeTradeSegment.equity => 'Equity',
        HomeTradeSegment.fno => 'F&O',
        HomeTradeSegment.commodity => 'Commodity',
      };

  String get categoryLabel => switch (category) {
        HomeTradeCategory.intraday => 'Intraday',
        HomeTradeCategory.swing => 'Swing',
        HomeTradeCategory.positional => 'Long-term',
        HomeTradeCategory.btst => 'BTST',
      };

  HomeTrade copyWith({
    String? id,
    String? symbol,
    String? companyName,
    HomeTradeDirection? direction,
    HomeTradeSegment? segment,
    HomeTradeCategory? category,
    HomeTradeState? state,
    double? entry,
    double? sl,
    double? t1,
    double? t2,
    double? t3,
    double? ltp,
    double? pnlPercent,
    double? runningPnlPercent,
    String? batchName,
    String? analystName,
    String? analystAvatarUrl,
    double? analystWinRate,
    String? logoUrl,
    String? rationale,
    DateTime? nseTimestamp,
    DateTime? entryTimestamp,
    List<TradeTarget>? targets,
    List<String>? hitTargets,
    List<TradeModification>? modifications,
    String? planId,
  }) {
    return HomeTrade(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      companyName: companyName ?? this.companyName,
      direction: direction ?? this.direction,
      segment: segment ?? this.segment,
      category: category ?? this.category,
      state: state ?? this.state,
      entry: entry ?? this.entry,
      sl: sl ?? this.sl,
      t1: t1 ?? this.t1,
      t2: t2 ?? this.t2,
      t3: t3 ?? this.t3,
      ltp: ltp ?? this.ltp,
      pnlPercent: pnlPercent ?? this.pnlPercent,
      runningPnlPercent: runningPnlPercent ?? this.runningPnlPercent,
      batchName: batchName ?? this.batchName,
      analystName: analystName ?? this.analystName,
      analystAvatarUrl: analystAvatarUrl ?? this.analystAvatarUrl,
      analystWinRate: analystWinRate ?? this.analystWinRate,
      logoUrl: logoUrl ?? this.logoUrl,
      rationale: rationale ?? this.rationale,
      nseTimestamp: nseTimestamp ?? this.nseTimestamp,
      entryTimestamp: entryTimestamp ?? this.entryTimestamp,
      targets: targets ?? this.targets,
      hitTargets: hitTargets ?? this.hitTargets,
      modifications: modifications ?? this.modifications,
      planId: planId ?? this.planId,
    );
  }
}
class TradeTarget {
  const TradeTarget({required this.price, required this.bookPercent});
  final double price;
  final double bookPercent;
}

class TradeModification {
  const TradeModification({
    required this.modifiedAt,
    required this.modifiedBy,
    required this.reason,
    required this.fieldsChanged,
  });
  final DateTime modifiedAt;
  final String modifiedBy;
  final String reason;
  final Map<String, dynamic> fieldsChanged;
}

