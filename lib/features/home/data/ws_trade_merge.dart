import '../../../core/network/ws_trade_event.dart';
import '../domain/entities/home_trade.dart';
import 'models/home_trade_model.dart';

/// Applies backend WebSocket trade payloads onto in-memory [HomeTrade] lists.
class WsTradeMerge {
  const WsTradeMerge._();

  static bool _payloadHasLevelFields(Map<String, dynamic> payload) {
    return payload.containsKey('stop_loss') ||
        payload.containsKey('target') ||
        payload.containsKey('targets');
  }

  static bool _tradeLevelsChanged(HomeTrade before, HomeTrade after) {
    return before.sl != after.sl ||
        before.t1 != after.t1 ||
        before.t2 != after.t2 ||
        before.t3 != after.t3 ||
        before.targets.length != after.targets.length;
  }

  static List<TradeTarget> targetsFromPayload(dynamic raw) {
    if (raw is! List || raw.isEmpty) return const <TradeTarget>[];
    return raw
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .map(
          (map) => TradeTarget(
            price: (map['target_price'] as num?)?.toDouble() ?? 0,
            bookPercent: (map['book_percent'] as num?)?.toDouble() ??
                (map['exit_percent'] as num?)?.toDouble() ??
                100,
          ),
        )
        .toList();
  }

  static (double t1, double? t2, double? t3) tierTargets(
    List<TradeTarget> targets,
    double entry,
    double? singleTarget,
  ) {
    if (targets.isNotEmpty) {
      final prices = targets.map((t) => t.price).toList();
      return (
        prices.first,
        prices.length > 1 ? prices[1] : null,
        prices.length > 2 ? prices[2] : null,
      );
    }
    if (singleTarget != null) {
      return (singleTarget, null, null);
    }
    return (entry, null, null);
  }

  static HomeTrade applyModified(HomeTrade trade, Map<String, dynamic> event) {
    final payload = event;

    double? readSl;
    if (payload.containsKey('stop_loss')) {
      final v = payload['stop_loss'];
      readSl = v == null ? trade.sl : (v as num?)?.toDouble() ?? trade.sl;
    }

    double? singleTarget;
    if (payload.containsKey('target')) {
      final v = payload['target'];
      singleTarget =
          v == null ? null : (v as num?)?.toDouble();
    }

    List<TradeTarget>? targets;
    if (payload.containsKey('targets')) {
      final parsed = targetsFromPayload(payload['targets']);
      targets = parsed;
    }

    final tier = tierTargets(
      targets ?? trade.targets,
      trade.entry,
      singleTarget ?? trade.t1,
    );

    HomeTradeState? nextState;
    if (payload.containsKey('status')) {
      nextState = HomeTradeModel.stateFromApi(
        payload['status']?.toString(),
      );
    }

    final reason = (payload['modification_reason'] as String?)?.trim() ?? '';
    final summary = (payload['changes_summary'] as String?)?.trim() ?? '';
    final modifiedFields = payload['modified_fields'];
    List<TradeModification> mods = trade.modifications;
    if (reason.isNotEmpty ||
        summary.isNotEmpty ||
        modifiedFields is List && modifiedFields.isNotEmpty) {
      final ts = _eventTime(payload);
      mods = [
        ...mods,
        TradeModification(
          modifiedAt: ts,
          modifiedBy: (payload['analyst_name'] as String?)?.trim().isNotEmpty ==
                  true
              ? (payload['analyst_name'] as String).trim()
              : (payload['analyst_id']?.toString() ?? 'Analyst'),
          reason: reason.isNotEmpty ? reason : summary,
          fieldsChanged: <String, dynamic>{
            if (modifiedFields is List) 'modified_fields': modifiedFields,
            if (payload.containsKey('old_stop_loss') ||
                payload.containsKey('stop_loss'))
              'stop_loss': <String, dynamic>{
                'old': payload['old_stop_loss'],
                'new': payload['stop_loss'] ?? readSl ?? trade.sl,
              },
            if (payload.containsKey('old_target') ||
                payload.containsKey('targets'))
              'targets': <String, dynamic>{
                'old': payload['old_target'] ?? payload['old_targets'],
                'new': payload['targets'] ?? targets ?? trade.targets,
              },
          },
        ),
      ];
    }

    return trade.copyWith(
      sl: readSl ?? trade.sl,
      t1: tier.$1,
      t2: tier.$2,
      t3: tier.$3,
      targets: targets ?? trade.targets,
      state: nextState ?? trade.state,
      modifications: mods,
    );
  }

  static HomeTrade applyClosed(HomeTrade trade, Map<String, dynamic> event) {
    final statusRaw = (event['status'] ?? event['closure_type'])?.toString();
    final state = statusRaw != null && statusRaw.isNotEmpty
        ? HomeTradeModel.stateFromApi(statusRaw)
        : HomeTradeState.manuallyClosed;

    return trade.copyWith(
      state: state,
      exitPrice: (event['exit_price'] as num?)?.toDouble() ?? trade.exitPrice,
      pnlPercent:
          (event['pnl_percent'] as num?)?.toDouble() ?? trade.pnlPercent,
      exitTimestamp: _eventTime(event),
    );
  }

  static HomeTrade? tryParseCreated(Map<String, dynamic> event) {
    final id = event['trade_id']?.toString();
    if (id == null || id.isEmpty) return null;
    if ((event['symbol'] as String?)?.trim().isEmpty ?? true) {
      return null;
    }
    try {
      final json = Map<String, dynamic>.from(event);
      json['trade_id'] ??= id;
      return HomeTradeModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static DateTime _eventTime(Map<String, dynamic> event) {
    final ts = event['timestamp'];
    if (ts is num) {
      final ms = ts > 1e12 ? ts.toInt() : (ts * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
    return DateTime.now();
  }

  /// Returns updated list and optional toast text from `changes_summary`.
  static ({List<HomeTrade> trades, String? toast, bool needsRefetch})
      applyEvent({
    required List<HomeTrade> trades,
    required WsTradeEventKind kind,
    required Map<String, dynamic> payload,
  }) {
    final tradeId = payload['trade_id']?.toString();
    if (tradeId == null || tradeId.isEmpty) {
      return (trades: trades, toast: null, needsRefetch: false);
    }

    switch (kind) {
      case WsTradeEventKind.modified:
        final index = trades.indexWhere((t) => t.id == tradeId);
        if (index < 0) {
          return (trades: trades, toast: null, needsRefetch: true);
        }
        if (!_payloadHasLevelFields(payload)) {
          return (trades: trades, toast: null, needsRefetch: true);
        }
        final updated = List<HomeTrade>.from(trades);
        final before = updated[index];
        final after = applyModified(before, payload);
        updated[index] = after;
        if (!_tradeLevelsChanged(before, after)) {
          return (trades: trades, toast: null, needsRefetch: true);
        }
        final toast = (payload['changes_summary'] as String?)?.trim();
        return (
          trades: updated,
          toast: toast != null && toast.isNotEmpty ? toast : 'Trade updated',
          needsRefetch: false,
        );

      case WsTradeEventKind.closed:
        final index = trades.indexWhere((t) => t.id == tradeId);
        if (index < 0) {
          return (trades: trades, toast: null, needsRefetch: false);
        }
        final updated = List<HomeTrade>.from(trades);
        updated[index] = applyClosed(updated[index], payload);
        return (
          trades: updated,
          toast: 'Trade closed',
          needsRefetch: false,
        );

      case WsTradeEventKind.created:
        if (trades.any((t) => t.id == tradeId)) {
          return (trades: trades, toast: null, needsRefetch: false);
        }
        final created = tryParseCreated(payload);
        if (created != null) {
          return (
            trades: <HomeTrade>[created, ...trades],
            toast: 'New trade published',
            needsRefetch: false,
          );
        }
        return (trades: trades, toast: null, needsRefetch: true);

      case WsTradeEventKind.unknown:
        return (trades: trades, toast: null, needsRefetch: false);
    }
  }

  /// Updates separate active / closed lists (Trades tab, advisor profile).
  static ({
    List<HomeTrade> active,
    List<HomeTrade> closed,
    bool needsRefetch,
  }) applyToActiveClosed({
    required List<HomeTrade> active,
    required List<HomeTrade> closed,
    required WsTradeEventKind kind,
    required Map<String, dynamic> payload,
  }) {
    switch (kind) {
      case WsTradeEventKind.modified:
        final activeResult = applyEvent(
          trades: active,
          kind: kind,
          payload: payload,
        );
        final closedResult = applyEvent(
          trades: closed,
          kind: kind,
          payload: payload,
        );
        return (
          active: activeResult.trades,
          closed: closedResult.trades,
          needsRefetch: false,
        );

      case WsTradeEventKind.closed:
        final tradeId = payload['trade_id']?.toString();
        if (tradeId == null || tradeId.isEmpty) {
          return (active: active, closed: closed, needsRefetch: false);
        }
        HomeTrade? existing;
        for (final t in active) {
          if (t.id == tradeId) {
            existing = t;
            break;
          }
        }
        if (existing == null) {
          for (final t in closed) {
            if (t.id == tradeId) {
              existing = t;
              break;
            }
          }
        }

        var nextActive = active.where((t) => t.id != tradeId).toList();
        var nextClosed = closed.where((t) => t.id != tradeId).toList();

        if (existing != null) {
          final closedTrade = applyClosed(existing, payload);
          nextClosed = <HomeTrade>[closedTrade, ...nextClosed];
        }
        return (
          active: nextActive,
          closed: nextClosed,
          needsRefetch: existing == null,
        );

      case WsTradeEventKind.created:
        final activeResult = applyEvent(
          trades: active,
          kind: kind,
          payload: payload,
        );
        return (
          active: activeResult.trades,
          closed: closed,
          needsRefetch: activeResult.needsRefetch,
        );

      case WsTradeEventKind.unknown:
        return (active: active, closed: closed, needsRefetch: false);
    }
  }
}
