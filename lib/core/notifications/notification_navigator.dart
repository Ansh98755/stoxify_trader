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
    await open(payload);
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

    final entityType = payload.entityType;
    if (entityType == 'TRADE') {
      final tradeId = payload.tradeId ?? payload.entityId;
      if (tradeId != null && tradeId.isNotEmpty) {
        await _push(
          ctx,
          '${AppRoutingName.tradeDetails}?tradeId=${Uri.encodeQueryComponent(tradeId)}',
        );
        return;
      }
    } else if (entityType == 'PLAN') {
      final planId = payload.planId ?? payload.entityId;
      if (planId != null && planId.isNotEmpty) {
        await _push(
          ctx,
          '${AppRoutingName.batchDetails}?planId=${Uri.encodeQueryComponent(planId)}',
        );
        return;
      }
    } else if (entityType == 'ANALYST') {
      final analystId = payload.analystId ?? payload.entityId;
      if (analystId != null && analystId.isNotEmpty) {
        await _push(
          ctx,
          '${AppRoutingName.advisorProfile}?analystId=${Uri.encodeQueryComponent(analystId)}',
        );
        return;
      }
    } else if (entityType == 'SUBSCRIPTION') {
      final type = payload.type.toUpperCase();
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
      final subId = payload.subscriptionId ?? payload.entityId;
      if (subId != null && subId.isNotEmpty) {
        await _push(
          ctx,
          '${AppRoutingName.mySubscriptions}?subscriptionId=${Uri.encodeQueryComponent(subId)}',
        );
        return;
      }
      await _push(ctx, AppRoutingName.mySubscriptions);
      return;
    }

    final tradeId = payload.tradeId;
    if (tradeId != null && tradeId.isNotEmpty) {
      await _push(
        ctx,
        '${AppRoutingName.tradeDetails}?tradeId=${Uri.encodeQueryComponent(tradeId)}',
      );
      return;
    }

    await _push(ctx, AppRoutingName.notifications);
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
      if (relatedEntityType != null) 'related_entity_type': relatedEntityType,
      if (relatedEntityId != null) 'related_entity_id': relatedEntityId,
    };
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
        normalized.startsWith('/home')) {
      final uri = Uri.parse(normalized);
      final qp = Map<String, String>.from(uri.queryParameters);
      if (!qp.containsKey('tradeId') && payload.tradeId != null) {
        qp['tradeId'] = payload.tradeId!;
      }
      if (!qp.containsKey('planId') && payload.planId != null) {
        qp['planId'] = payload.planId!;
      }
      if (!qp.containsKey('analystId') && payload.analystId != null) {
        qp['analystId'] = payload.analystId!;
      }
      final target = uri.replace(queryParameters: qp.isEmpty ? null : qp);
      if (!ctx.mounted) return false;
      if (target.path == AppRoutingName.home) {
        ctx.go(target.toString());
      } else {
        await ctx.push(target.toString());
      }
      return true;
    }

    return false;
  }
}
