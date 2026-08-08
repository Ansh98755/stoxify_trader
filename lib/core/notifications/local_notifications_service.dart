import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../platform/app_platform.dart';
import 'push_payload.dart';

/// Shows foreground OS banners with the custom StoXify chime sound.
///
/// Sound asset names (must match native files):
/// - Android: `res/raw/notification_chime.wav` → sound `notification_chime`
/// - iOS: `Runner/notification_chime.wav` → sound `notification_chime.wav`
///
/// No-op early exit on web only — mobile path is unchanged.
/// Must stay in sync with [StoXifyApplication.CHANNEL_ID] on Android.
class LocalNotificationsService {
  LocalNotificationsService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'stoxify_alerts_chime_v3';
  static const List<String> _legacyChannelIds = <String>[
    'stoxify_alerts',
    'stoxify_alerts_chime_v1',
    'stoxify_alerts_chime_v2',
  ];
  static const String channelName = 'StoXify Alerts';
  static const String channelDescription =
      'Trades, subscriptions, and market price alerts';

  /// Filename without extension for Android raw resource.
  static const String androidSoundName = 'notification_chime';

  /// Full filename for iOS bundle sound.
  static const String iosSoundName = 'notification_chime.wav';

  static const MethodChannel _soundChannel =
      MethodChannel('stoxify/notification_sound');

  static bool _ready = false;
  static void Function(PushPayload payload)? onSelect;

  static Future<void> initialize({
    void Function(PushPayload payload)? onNotificationTap,
  }) async {
    if (kIsWeb) return;
    if (onNotificationTap != null) {
      onSelect = onNotificationTap;
    }
    if (_ready) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (AppPlatform.isAndroid) {
      await _ensureAndroidChannel();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    }

    _ready = true;
  }

  /// Safe to call from the FCM background isolate (no tap callback required).
  static Future<void> ensureReady() => initialize();

  /// Plays the chime via Android MediaPlayer (notification audio stream).
  static Future<void> playChime() async {
    if (kIsWeb || !AppPlatform.isAndroid) return;
    try {
      await _soundChannel.invokeMethod<void>('playChime');
    } catch (e) {
      debugPrint('[FCM] playChime failed: $e');
    }
  }

  static Future<void> _ensureAndroidChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    for (final id in <String>[..._legacyChannelIds, channelId]) {
      try {
        await android.deleteNotificationChannel(id);
      } catch (_) {}
    }

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(androidSoundName),
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      ),
    );
  }

  static void _onResponse(NotificationResponse response) {
    final payload = _payloadFromString(response.payload);
    if (payload != null) onSelect?.call(payload);
  }

  static PushPayload? _payloadFromString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map) {
        return PushPayload.fromMap(map.cast<String, dynamic>());
      }
    } catch (e) {
      debugPrint('[FCM] local payload decode failed: $e');
    }
    return null;
  }

  /// If the app was launched by tapping a local notification.
  static Future<PushPayload?> getLaunchPayload() async {
    if (kIsWeb) return null;
    await ensureReady();
    if (!_ready) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return _payloadFromString(details!.notificationResponse?.payload);
  }

  static Future<void> showFromPush(
    PushPayload payload, {
    bool playTraySound = true,
    bool playFallbackChime = false,
  }) async {
    if (kIsWeb) return;
    await ensureReady();
    if (!_ready) return;

    final title = payload.title?.isNotEmpty == true
        ? payload.title!
        : _defaultTitle(payload.type);
    final body = _composeBody(payload);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: playTraySound,
      sound: playTraySound
          ? const RawResourceAndroidNotificationSound(androidSoundName)
          : null,
      enableVibration: true,
      tag: payload.androidTag,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
      category: AndroidNotificationCategory.message,
      audioAttributesUsage: AudioAttributesUsage.notification,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: iosSoundName,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final id = payload.notificationId?.hashCode.abs() ??
        payload.androidTag.hashCode.abs() % 1000000;

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(payload.toLocalPayload()),
    );

    if (playFallbackChime) {
      await playChime();
    }
  }

  static String _defaultTitle(String type) {
    switch (type.toUpperCase()) {
      case PushTypes.tradeCreated:
      case PushTypes.subscribedAnalystTrade:
        return 'New trade';
      case PushTypes.tradePriceUpdate:
        return 'Price update';
      case PushTypes.tradeHighProfit:
        return 'Strong move';
      case PushTypes.tradeValueOpportunity:
        return 'Opportunity';
      case PushTypes.planCreated:
        return 'New plan';
      case PushTypes.batchCreated:
        return 'New batch';
      case PushTypes.subscriptionActivated:
        return 'Subscription active';
      case PushTypes.subscriptionExpiring:
        return 'Subscription expiring';
      case PushTypes.subscriptionExpired:
        return 'Subscription expired';
      default:
        return 'StoXify';
    }
  }

  static String _composeBody(PushPayload payload) {
    final base = payload.body?.trim();
    final parts = <String>[];
    if (base != null && base.isNotEmpty) parts.add(base);

    final symbol = payload.symbol;
    final ltp = payload.ltp;
    final change = payload.changePct;
    if (symbol != null || ltp != null || change != null) {
      final priceBits = <String>[];
      if (symbol != null) priceBits.add(symbol);
      if (ltp != null) priceBits.add('LTP ₹$ltp');
      if (change != null) {
        final signed = change.startsWith('+') || change.startsWith('-')
            ? change
            : '+$change';
        priceBits.add('$signed%');
      }
      final line = priceBits.join(' · ');
      if (parts.isEmpty || !(parts.last.contains(line))) {
        parts.add(line);
      }
    }

    return parts.isEmpty ? 'Open StoXify for details.' : parts.join('\n');
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Tap while app in background is handled when process resumes via
  // getNotificationAppLaunchDetails / onDidReceiveNotificationResponse.
}
