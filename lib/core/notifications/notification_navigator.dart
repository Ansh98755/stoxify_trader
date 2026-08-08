import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes/app_routing.dart';
import '../../app/routes/app_routing_name.dart';
import '../../features/notifications/domain/entities/app_notification.dart';
import 'push_payload.dart';

/// Maps a [PushPayload] (or inbox entity fields) to the correct app route.
class NotificationNavigator {
  NotificationNavigator._();

  /// Held when a push opens the app before auth/splash finishes.
  static PushPayload? pending;

  static void hold(PushPayload payload) {
    pending = payload;
  }

  /// Consume + navigate if a pending deep link exists.
  static Future<void> flushPending() async {
    final payload = pending;
    if (payload == null) return;
    pending = null;
    // Wait until the destination route (usually home) is mounted.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await open(payload);
  }

  /// Schedule [flushPending] after the next frame (post `context.go`).
  static void flushPendingAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.microtask(() async {
        await flushPending();
      });
    });
  }

  static Future<void> open(PushPayload payload) async {
    final ctx = AppRouting.rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      hold(payload);
      return;
    }

    final route = payload.route?.trim();
    if (route != null && route.isNotEmpty) {
      if (await _tryOpenLegacyRoute(ctx, route, payload)) return;
    }

    if (!ctx.mounted) {
      hold(payload);
      return;
    }

    final type = payload.type.toUpperCase();
    final entityType = (payload.entityType ?? '').toUpperCase();

    // ── Trade alerts → trade details ─────────────────────────────────────
    if (_isTradeNotification(type, entityType)) {
      final tradeId = _firstNonEmpty(<String?>[
        payload.tradeId,
        payload.entityId,
      ]);
      if (tradeId != null) {
        await _push(
          ctx,
          '${AppRoutingName.tradeDetails}?tradeId=${Uri.encodeQueryComponent(tradeId)}',
        );
        return;
      }
    }

    // ── Plan / batch → batch details ─────────────────────────────────────
    if (_isPlanNotification(type, entityType)) {
      final planId = _firstNonEmpty(<String?>[
        payload.planId,
        if (entityType == 'PLAN') payload.entityId,
        payload.batchId,
        if (entityType == 'BATCH') payload.entityId,
      ]);
      if (planId != null) {
        await _push(
          ctx,
          '${AppRoutingName.batchDetails}?planId=${Uri.encodeQueryComponent(planId)}',
        );
        return;
      }
    }

    // ── Analyst → advisor profile ────────────────────────────────────────
    if (_isAnalystNotification(type, entityType)) {
      final analystId = _firstNonEmpty(<String?>[
        payload.analystId,
        payload.entityId,
      ]);
      if (analystId != null) {
        await _push(
          ctx,
          '${AppRoutingName.advisorProfile}?analystId=${Uri.encodeQueryComponent(analystId)}',
        );
        return;
      }
    }

    // ── Subscriptions ────────────────────────────────────────────────────
    if (_isSubscriptionNotification(type, entityType)) {
      if (type == PushTypes.subscriptionExpiring ||
          type == PushTypes.subscriptionExpired) {
        final planId = payload.planId;
        final analystId = payload.analystId;
        if (planId != null &&
            planId.isNotEmpty &&
            analystId != null &&
            analystId.isNotEmpty) {
          final q = <String, String>{
            'planId': planId,
            'analystId': analystId,
            if (payload.batchId != null && payload.batchId!.isNotEmpty)
              'batchId': payload.batchId!,
          };
          await _push(
            ctx,
            Uri(path: AppRoutingName.subscriptions, queryParameters: q)
                .toString(),
          );
          return;
        }
      }

      final subId = _firstNonEmpty(<String?>[
        payload.subscriptionId,
        if (entityType == 'SUBSCRIPTION') payload.entityId,
      ]);
      if (subId != null) {
        await _push(
          ctx,
          '${AppRoutingName.mySubscriptions}?subscriptionId=${Uri.encodeQueryComponent(subId)}',
        );
        return;
      }
      await _push(ctx, AppRoutingName.mySubscriptions);
      return;
    }

    // ── Broadcasts / unknown with no entity → inbox ──────────────────────
    if (type == PushTypes.adminBroadcast ||
        type == PushTypes.systemAnnouncement) {
      await _push(ctx, AppRoutingName.notifications);
      return;
    }

    // Last-chance ID heuristics (malformed payloads).
    final tradeId = payload.tradeId;
    if (tradeId != null && tradeId.isNotEmpty) {
      await _push(
        ctx,
        '${AppRoutingName.tradeDetails}?tradeId=${Uri.encodeQueryComponent(tradeId)}',
      );
      return;
    }
    final planId = payload.planId ?? payload.batchId;
    if (planId != null && planId.isNotEmpty) {
      await _push(
        ctx,
        '${AppRoutingName.batchDetails}?planId=${Uri.encodeQueryComponent(planId)}',
      );
      return;
    }
    final analystId = payload.analystId;
    if (analystId != null && analystId.isNotEmpty) {
      await _push(
        ctx,
        '${AppRoutingName.advisorProfile}?analystId=${Uri.encodeQueryComponent(analystId)}',
      );
      return;
    }

    await _push(ctx, AppRoutingName.notifications);
  }

  static bool _isTradeNotification(String type, String entityType) {
    if (entityType == 'TRADE') return true;
    return type == PushTypes.tradeCreated ||
        type == PushTypes.tradeClosed ||
        type == PushTypes.tradeModified ||
        type == PushTypes.tradePriceUpdate ||
        type == PushTypes.tradeValueOpportunity ||
        type == PushTypes.tradeHighProfit ||
        type == PushTypes.subscribedAnalystTrade;
  }

  static bool _isPlanNotification(String type, String entityType) {
    if (entityType == 'PLAN' || entityType == 'BATCH') return true;
    return type == PushTypes.planCreated || type == PushTypes.batchCreated;
  }

  static bool _isAnalystNotification(String type, String entityType) {
    if (entityType == 'ANALYST' || entityType == 'ADVISOR') return true;
    return type == 'ANALYST_UPDATE' || type == 'ANALYST_CREATED';
  }

  static bool _isSubscriptionNotification(String type, String entityType) {
    if (entityType == 'SUBSCRIPTION') return true;
    return type == PushTypes.subscriptionActivated ||
        type == PushTypes.subscriptionExpiring ||
        type == PushTypes.subscriptionExpired;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      final t = v?.trim();
      if (t != null && t.isNotEmpty) return t;
    }
    return null;
  }

  static Future<void> _push(BuildContext ctx, String location) async {
    if (!ctx.mounted) return;
    await ctx.push(location);
  }

  /// Inbox list helper — same navigation rules as FCM.
  static Future<void> openFromInbox({
    required AppNotificationType type,
    String? relatedEntityType,
    String? relatedEntityId,
    Map<String, dynamic>? payload,
  }) async {
    final merged = <String, dynamic>{
      ...?payload,
      'type': _backendType(type),
      if (relatedEntityType != null && relatedEntityType.trim().isNotEmpty)
        'related_entity_type': relatedEntityType,
      if (relatedEntityId != null && relatedEntityId.trim().isNotEmpty)
        'related_entity_id': relatedEntityId,
    };
    // Prefer explicit IDs from inbox entity when payload omitted them.
    final entity = (relatedEntityType ?? '').trim().toUpperCase();
    final id = relatedEntityId?.trim();
    if (id != null && id.isNotEmpty) {
      merged.putIfAbsent(
        switch (entity) {
          'TRADE' => 'trade_id',
          'PLAN' || 'BATCH' => 'plan_id',
          'ANALYST' || 'ADVISOR' => 'analyst_id',
          'SUBSCRIPTION' => 'subscription_id',
          _ => 'related_entity_id',
        },
        () => id,
      );
    }
    await open(PushPayload.fromMap(merged));
  }

  static String _backendType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.tradeCreated:
        return PushTypes.tradeCreated;
      case AppNotificationType.tradeClosed:
        return PushTypes.tradeClosed;
      case AppNotificationType.tradeModified:
        return PushTypes.tradeModified;
      case AppNotificationType.tradePriceUpdate:
        return PushTypes.tradePriceUpdate;
      case AppNotificationType.tradeValueOpportunity:
        return PushTypes.tradeValueOpportunity;
      case AppNotificationType.tradeHighProfit:
        return PushTypes.tradeHighProfit;
      case AppNotificationType.planCreated:
        return PushTypes.planCreated;
      case AppNotificationType.batchCreated:
        return PushTypes.batchCreated;
      case AppNotificationType.subscriptionActivated:
        return PushTypes.subscriptionActivated;
      case AppNotificationType.subscriptionExpiring:
        return PushTypes.subscriptionExpiring;
      case AppNotificationType.subscriptionExpired:
        return PushTypes.subscriptionExpired;
      case AppNotificationType.adminBroadcast:
        return PushTypes.adminBroadcast;
      case AppNotificationType.other:
        return 'OTHER';
    }
  }

  static Future<bool> _tryOpenLegacyRoute(
    BuildContext ctx,
    String route,
    PushPayload payload,
  ) async {
    if (!ctx.mounted) return false;

    final normalized = route.startsWith('/') ? route : '/$route';
    final parts = normalized.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      final kind = parts[0].toUpperCase();
      final id = parts[1];
      switch (kind) {
        case 'TRADE':
          await _push(
            ctx,
            '${AppRoutingName.tradeDetails}?tradeId=${Uri.encodeQueryComponent(id)}',
          );
          return true;
        case 'PLAN':
        case 'BATCH':
          await _push(
            ctx,
            '${AppRoutingName.batchDetails}?planId=${Uri.encodeQueryComponent(id)}',
          );
          return true;
        case 'ANALYST':
        case 'ADVISOR':
          await _push(
            ctx,
            '${AppRoutingName.advisorProfile}?analystId=${Uri.encodeQueryComponent(id)}',
          );
          return true;
        case 'SUBSCRIPTION':
          await _push(
            ctx,
            '${AppRoutingName.mySubscriptions}?subscriptionId=${Uri.encodeQueryComponent(id)}',
          );
          return true;
        case 'HOME':
          if (ctx.mounted) ctx.go(AppRoutingName.home);
          return true;
        case 'NOTIFICATIONS':
        case 'NOTIFICATION':
          await _push(ctx, AppRoutingName.notifications);
          return true;
      }
    }

    if (normalized.startsWith('/trade-details') ||
        normalized.startsWith('/batch-details') ||
        normalized.startsWith('/advisor-profile') ||
        normalized.startsWith('/subscriptions') ||
        normalized.startsWith('/my-subscriptions') ||
        normalized.startsWith('/notifications') ||
        normalized.startsWith('/home') ||
        normalized.startsWith('/trade-feed') ||
        normalized.startsWith('/discover')) {
      final uri = Uri.parse(normalized);
      final qp = Map<String, String>.from(uri.queryParameters);
      if (!qp.containsKey('tradeId') && payload.tradeId != null) {
        qp['tradeId'] = payload.tradeId!;
      }
      if (!qp.containsKey('planId') &&
          (payload.planId != null || payload.batchId != null)) {
        qp['planId'] = (payload.planId ?? payload.batchId)!;
      }
      if (!qp.containsKey('analystId') && payload.analystId != null) {
        qp['analystId'] = payload.analystId!;
      }
      if (!qp.containsKey('subscriptionId') &&
          payload.subscriptionId != null) {
        qp['subscriptionId'] = payload.subscriptionId!;
      }
      final target = uri.replace(queryParameters: qp.isEmpty ? null : qp);
      if (!ctx.mounted) return false;
      if (target.path == AppRoutingName.home ||
          target.path == AppRoutingName.tradeFeed ||
          target.path == AppRoutingName.discover) {
        ctx.go(target.toString());
      } else {
        await ctx.push(target.toString());
      }
      return true;
    }

    return false;
  }
}
