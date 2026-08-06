import '../../domain/entities/home_trade.dart';

class HomeTradeModel {
  const HomeTradeModel._();

  static HomeTrade fromJson(Map<String, dynamic> json) {
    final isPairTrade =
        (json['trade_type'] as String?)?.toUpperCase() == 'PAIR';
    final leg = isPairTrade
        ? (json['leg1'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{}
        : json;

    final entry = (leg['entry_price'] as num?)?.toDouble() ?? 0;
    final sl = (leg['stop_loss'] as num?)?.toDouble() ?? 0;

    final planned = ((leg['targets'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    final singleTarget = (leg['target'] as num?)?.toDouble();
    final targetPrices = planned.isNotEmpty
        ? planned
            .map((e) => (e['target_price'] as num?)?.toDouble() ?? 0)
            .toList()
        : <double?>[singleTarget].whereType<double>().toList();
    final t1 = targetPrices.isNotEmpty ? targetPrices[0] : entry;

    String symbol;
    if (isPairTrade) {
      final leg1 =
          (json['leg1'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{};
      final leg2 =
          (json['leg2'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{};
      final s1 = leg1['symbol'] as String? ?? '—';
      final s2 = leg2['symbol'] as String? ?? '—';
      symbol = '$s1 / $s2';
    } else {
      symbol = json['symbol'] as String? ?? '—';
    }

    final pnl = (json['combined_pnl_percent'] as num?)?.toDouble() ??
        (leg['pnl_percent'] as num?)?.toDouble() ??
        (json['pnl_percent'] as num?)?.toDouble();

    return HomeTrade(
      id: (json['trade_id'] ?? json['id'] ?? json['_id'])?.toString() ?? '',
      symbol: symbol,
      companyName: (leg['name'] as String?)?.trim().isNotEmpty == true
          ? (leg['name'] as String).trim()
          : null,
      direction: _direction(leg['direction'] as String?),
      segment: _segment(json['segment'] as String?),
      category: _category(json['category'] as String?),
      state: _state((json['status'] ?? json['state'] ?? json['trade_status'])?.toString()),
      entry: entry,
      sl: sl,
      t1: t1,
      t2: targetPrices.length > 1 ? targetPrices[1] : null,
      t3: targetPrices.length > 2 ? targetPrices[2] : null,
      ltp: (leg['ltp'] as num?)?.toDouble(),
      pnlPercent: pnl,
      runningPnlPercent: (leg['running_pnl_percent'] as num?)?.toDouble(),
      batchName: _batchName(json['batch']),
      analystId: (json['analyst_id'] ?? json['analystId'])?.toString(),
      analystName: json['analyst_name'] as String?,
      logoUrl: json['logo_url'] as String?,
      rationale: (json['rationale'] as String?)?.trim().isNotEmpty == true
          ? (json['rationale'] as String).trim()
          : null,
      nseTimestamp: _date(json['nse_timestamp']) ??
          _date(json['entry_timestamp']) ??
          DateTime.now(),
      analystAvatarUrl: json['analyst_avatar_url'] as String?,
      analystWinRate: (json['analyst_win_rate'] as num?)?.toDouble(),
      targets: planned.map((e) => TradeTarget(
        price: (e['target_price'] as num?)?.toDouble() ?? 0,
        bookPercent: (e['book_percent'] as num?)?.toDouble() ?? 100,
      )).toList(),
      hitTargets: ((json['hit_targets'] as List?) ?? [])
          .whereType<String>().toList(),
      entryTimestamp: _date(json['entry_timestamp']),
      modifications: _modifications(
        json['modification_history'],
        analystId: (json['analyst_id'] ?? json['analystId'])?.toString(),
        analystName: json['analyst_name'] as String?,
      ),
      planId: json['plan_id'] as String?,
    );
  }

  static String? _batchName(dynamic raw) {
    if (raw is String) {
      final s = raw.trim();
      return s.isEmpty ? null : s;
    }
    if (raw is List) {
      final names = raw
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return names.isEmpty ? null : names.join(' · ');
    }
    return null;
  }

  static HomeTradeDirection _direction(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'SHORT':
      case 'SELL':
        return HomeTradeDirection.short;
      default:
        return HomeTradeDirection.long;
    }
  }

  static HomeTradeSegment _segment(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'FNO':
      case 'CURRENCY':
        return HomeTradeSegment.fno;
      case 'COMMODITY':
        return HomeTradeSegment.commodity;
      default:
        return HomeTradeSegment.equity;
    }
  }

  static HomeTradeCategory _category(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'INTRADAY':
        return HomeTradeCategory.intraday;
      case 'SWING':
      case 'SHORT_TERM':
        return HomeTradeCategory.swing;
      case 'BTST':
        return HomeTradeCategory.btst;
      default:
        return HomeTradeCategory.positional;
    }
  }

  static HomeTradeState _state(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'LIVE':
      case 'ACTIVE':
      case 'OPEN':
      case 'PUBLISHED':
      case 'RUNNING':
      case 'OPEN_POSITION':
        return HomeTradeState.live;
      case 'CLOSED_BY_TARGET':
      case 'TARGET_HIT':
        return HomeTradeState.allTargetsHit;
      case 'CLOSED_BY_SL':
      case 'SL_HIT':
        return HomeTradeState.slHit;
      case 'EXPIRED':
        return HomeTradeState.expired;
      case 'MANUALLY_CLOSED':
      case 'CLOSED':
        return HomeTradeState.manuallyClosed;
      case 'T1_HIT':
        return HomeTradeState.t1Hit;
      case 'T2_HIT':
        return HomeTradeState.t2Hit;
      default:
        return HomeTradeState.live;
    }
  }

  static DateTime? _date(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
    return null;
  }

  static List<TradeModification> _modifications(
    dynamic raw, {
    String? analystId,
    String? analystName,
  }) {
    if (raw is! List) return const <TradeModification>[];
    return raw.whereType<Map>().map((e) {
      final map = e.cast<String, dynamic>();
      return TradeModification(
        modifiedAt: _date(map['modified_at']) ?? DateTime.now(),
        modifiedBy: _resolveModifiedBy(
          map['modified_by_name'] as String? ??
              map['modified_by_display_name'] as String? ??
              map['analyst_name'] as String? ??
              map['modified_by'] as String? ??
              '',
          analystId: analystId,
          analystName: analystName,
        ),
        reason: (map['reason'] as String?)?.trim() ?? '',
        fieldsChanged: (map['fields_changed'] as Map?)
                ?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );
    }).toList();
  }

  /// Prefer a display name over raw analyst IDs like `ANALYST_…`.
  static String _resolveModifiedBy(
    String raw, {
    String? analystId,
    String? analystName,
  }) {
    final by = raw.trim();
    final name = analystName?.trim() ?? '';
    if (name.isEmpty) return by.isEmpty ? '—' : by;

    if (by.isEmpty) return name;

    final id = (analystId ?? '').trim();
    final looksLikeId = by == id ||
        by.toUpperCase().startsWith('ANALYST_') ||
        by.toUpperCase().startsWith('USER_');
    if (looksLikeId) return name;

    return by;
  }
}
