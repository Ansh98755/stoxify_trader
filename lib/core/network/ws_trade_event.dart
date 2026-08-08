/// WebSocket trade lifecycle events (`trade.modified`, `trade.created`, `trade.closed`).
enum WsTradeEventKind { modified, created, closed, unknown }

class WsTradeEvent {
  const WsTradeEvent({
    required this.kind,
    required this.payload,
  });

  final WsTradeEventKind kind;
  final Map<String, dynamic> payload;

  String? get tradeId => resolveTradeId(payload);

  static String? resolveTradeId(Map<String, dynamic> msg) {
    for (final key in <String>[
      'trade_id',
      'tradeId',
      'related_entity_id',
      'relatedEntityId',
      'entity_id',
      'entityId',
      'id',
    ]) {
      final value = msg[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static Map<String, dynamic> flattenPayload(Map<String, dynamic> msg) {
    var base = Map<String, dynamic>.from(msg);

    for (final nestedKey in <String>['data', 'trade', 'payload', 'event']) {
      final nested = base[nestedKey];
      if (nested is Map) {
        base = <String, dynamic>{...base, ...nested.cast<String, dynamic>()};
      }
    }

    final leg1 = base['leg1'];
    if (leg1 is Map) {
      final leg = leg1.cast<String, dynamic>();
      if (!base.containsKey('stop_loss') && leg.containsKey('stop_loss')) {
        base['stop_loss'] = leg['stop_loss'];
      }
      if (!base.containsKey('target') && leg.containsKey('target')) {
        base['target'] = leg['target'];
      }
      if (!base.containsKey('targets') && leg.containsKey('targets')) {
        base['targets'] = leg['targets'];
      }
    }

    return base;
  }

  static WsTradeEventKind kindOf(Map<String, dynamic> msg) {
    final flat = flattenPayload(msg);
    final type = _normalizeType(_eventType(flat) ?? _eventType(msg));
    switch (type) {
      case 'trade.modified':
        return WsTradeEventKind.modified;
      case 'trade.created':
        return WsTradeEventKind.created;
      case 'trade.closed':
        return WsTradeEventKind.closed;
      default:
        break;
    }

    if (resolveTradeId(flat) != null && _looksLikeModification(flat)) {
      return WsTradeEventKind.modified;
    }
    return WsTradeEventKind.unknown;
  }

  static bool _looksLikeModification(Map<String, dynamic> flat) {
    return flat.containsKey('stop_loss') ||
        flat.containsKey('target') ||
        flat.containsKey('targets') ||
        flat.containsKey('modified_fields') ||
        flat.containsKey('changes_summary') ||
        flat.containsKey('old_stop_loss') ||
        flat.containsKey('old_target');
  }

  static String? _eventType(Map<String, dynamic> msg) {
    final raw = msg['type'] ?? msg['event_type'] ?? msg['notification_type'];
    return raw?.toString();
  }

  static String? _normalizeType(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized =
        raw.toUpperCase().replaceAll('.', '_').replaceAll('-', '_');
    switch (normalized) {
      case 'TRADE_MODIFIED':
      case 'TRADE_UPDATE':
      case 'TRADE_UPDATED':
        return 'trade.modified';
      case 'TRADE_CREATED':
        return 'trade.created';
      case 'TRADE_CLOSED':
        return 'trade.closed';
    }
    return raw.toLowerCase();
  }

  static WsTradeEvent? tryParse(dynamic rawMessage) {
    if (rawMessage is! Map) return null;
    final msg = rawMessage.cast<String, dynamic>();
    final flat = flattenPayload(msg);
    final kind = kindOf(msg);
    if (kind == WsTradeEventKind.unknown) return null;
    if (resolveTradeId(flat) == null) return null;
    return WsTradeEvent(kind: kind, payload: flat);
  }

  static bool isTradeLifecycleMessage(Map<String, dynamic> msg) {
    return kindOf(msg) != WsTradeEventKind.unknown;
  }
}
