/// Parsed FCM / local-notification data used for deep links and display.
///
/// Backend should send all values as strings in the FCM `data` map.
class PushPayload {
  const PushPayload({
    required this.type,
    this.notificationId,
    this.title,
    this.body,
    this.relatedEntityType,
    this.relatedEntityId,
    this.route,
    this.tradeId,
    this.planId,
    this.batchId,
    this.analystId,
    this.subscriptionId,
    this.symbol,
    this.ltp,
    this.changePct,
    this.collapseKey,
    this.raw = const <String, dynamic>{},
  });

  final String type;
  final String? notificationId;
  final String? title;
  final String? body;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final String? route;
  final String? tradeId;
  final String? planId;
  final String? batchId;
  final String? analystId;
  final String? subscriptionId;
  final String? symbol;
  final String? ltp;
  final String? changePct;
  final String? collapseKey;
  final Map<String, dynamic> raw;

  /// Canonical entity target for navigation.
  String? get entityType {
    final explicit = relatedEntityType?.trim().toUpperCase();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    switch (type.toUpperCase()) {
      case 'TRADE_CREATED':
      case 'TRADE_CLOSED':
      case 'TRADE_MODIFIED':
      case 'TRADE_PRICE_UPDATE':
      case 'TRADE_VALUE_OPPORTUNITY':
      case 'TRADE_HIGH_PROFIT':
      case 'SUBSCRIBED_ANALYST_TRADE':
        return 'TRADE';
      case 'PLAN_CREATED':
      case 'BATCH_CREATED':
        return 'PLAN';
      case 'SUBSCRIPTION_ACTIVATED':
      case 'SUBSCRIPTION_EXPIRING':
      case 'SUBSCRIPTION_EXPIRED':
        return 'SUBSCRIPTION';
      case 'ANALYST_UPDATE':
        return 'ANALYST';
      default:
        return null;
    }
  }

  String? get entityId {
    final related = relatedEntityId?.trim();
    if (related != null && related.isNotEmpty) return related;

    switch (entityType) {
      case 'TRADE':
        return tradeId;
      case 'PLAN':
        return planId;
      case 'ANALYST':
        return analystId;
      case 'SUBSCRIPTION':
        return subscriptionId;
      default:
        return null;
    }
  }

  /// Stable Android notification tag / collapse for replacements (e.g. LTP).
  String get androidTag {
    final key = collapseKey?.trim();
    if (key != null && key.isNotEmpty) return key;
    final id = notificationId?.trim();
    if (id != null && id.isNotEmpty) return id;
    final eid = entityId;
    if (eid != null && eid.isNotEmpty) return '${entityType ?? type}_$eid';
    return type.isEmpty ? 'stoxify_default' : type;
  }

  factory PushPayload.fromMap(Map<String, dynamic> data) {
    String? s(String key) {
      final v = data[key];
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    return PushPayload(
      type: (s('type') ?? s('notification_type') ?? 'OTHER').toUpperCase(),
      notificationId: s('notification_id'),
      title: s('title'),
      body: s('body') ?? s('message'),
      relatedEntityType: s('related_entity_type'),
      relatedEntityId: s('related_entity_id'),
      route: s('route'),
      tradeId: s('trade_id') ?? s('tradeId'),
      planId: s('plan_id') ?? s('planId'),
      batchId: s('batch_id') ?? s('batchId'),
      analystId: s('analyst_id') ?? s('analystId'),
      subscriptionId: s('subscription_id') ?? s('subscriptionId'),
      symbol: s('symbol'),
      ltp: s('ltp'),
      changePct: s('change_pct') ?? s('changePct'),
      collapseKey: s('collapse_key') ?? s('collapseKey') ?? s('tag'),
      raw: Map<String, dynamic>.from(data),
    );
  }

  /// Encodes for local-notification payload (JSON-ready primitives).
  Map<String, String> toLocalPayload() {
    final map = <String, String>{};
    void put(String k, String? v) {
      if (v != null && v.isNotEmpty) map[k] = v;
    }

    put('type', type);
    put('notification_id', notificationId);
    put('title', title);
    put('body', body);
    put('message', body);
    put('related_entity_type', relatedEntityType);
    put('related_entity_id', relatedEntityId);
    put('route', route);
    put('trade_id', tradeId);
    put('plan_id', planId);
    put('batch_id', batchId);
    put('analyst_id', analystId);
    put('subscription_id', subscriptionId);
    put('symbol', symbol);
    put('ltp', ltp);
    put('change_pct', changePct);
    put('collapse_key', collapseKey);
    return map;
  }
}

/// Well-known push type strings aligned with backend contract.
abstract final class PushTypes {
  static const tradeCreated = 'TRADE_CREATED';
  static const tradeClosed = 'TRADE_CLOSED';
  static const tradeModified = 'TRADE_MODIFIED';
  static const tradePriceUpdate = 'TRADE_PRICE_UPDATE';
  static const tradeValueOpportunity = 'TRADE_VALUE_OPPORTUNITY';
  static const tradeHighProfit = 'TRADE_HIGH_PROFIT';
  static const subscribedAnalystTrade = 'SUBSCRIBED_ANALYST_TRADE';
  static const planCreated = 'PLAN_CREATED';
  static const batchCreated = 'BATCH_CREATED';
  static const subscriptionActivated = 'SUBSCRIPTION_ACTIVATED';
  static const subscriptionExpiring = 'SUBSCRIPTION_EXPIRING';
  static const subscriptionExpired = 'SUBSCRIPTION_EXPIRED';
  static const adminBroadcast = 'ADMIN_BROADCAST';
  static const systemAnnouncement = 'SYSTEM_ANNOUNCEMENT';
}
