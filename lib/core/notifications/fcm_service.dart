import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../di/injection.dart';
import '../network/device_id.dart';
import '../platform/app_platform.dart';
import '../storage/secure_storage.dart';
import 'local_notifications_service.dart';
import 'notification_navigator.dart';
import 'push_payload.dart';
import 'push_token_api.dart';

/// Top-level background handler — must not capture non-serializable state.
/// Registered only on mobile (see main.dart).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('[FCM] background Firebase init: $e');
  }
  debugPrint(
    '[FCM] background message: ${message.messageId} type=${message.data['type']}',
  );
}

/// Owns FCM permission, token lifecycle, and message → UI / deep-link wiring.
class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  /// Instantiated only after Firebase is ready (mobile path matches prior usage
  /// once [initialize] runs successfully).
  FirebaseMessaging? _messaging;

  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _openSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  bool _started = false;
  String? _lastToken;

  String? get currentToken => _lastToken;

  static String get _platform => AppPlatform.pushPlatform;

  Future<void> initialize() async {
    if (_started) return;
    _started = true;

    // Web may boot without Firebase; mobile always initializes in main first.
    if (kIsWeb && Firebase.apps.isEmpty) {
      debugPrint('[FCM] skip — Firebase not initialized (web)');
      return;
    }
    if (Firebase.apps.isEmpty) {
      // Mobile: fail soft only if native init truly missing (should not happen).
      debugPrint('[FCM] skip — Firebase not initialized');
      return;
    }

    // Local system banners: mobile only (unchanged).
    if (!kIsWeb) {
      await LocalNotificationsService.initialize(
        onNotificationTap: (payload) {
          unawaited(NotificationNavigator.open(payload));
        },
      );
    }

    final messaging = FirebaseMessaging.instance;
    _messaging = messaging;

    // Mobile-only presentation options (same as before).
    if (!kIsWeb) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    await _requestPermission();

    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForeground);
    _openSub = FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);

    try {
      final o = Firebase.app().options;
      final token = await _readFcmToken();
      debugPrint('projectId: ${o.projectId}');
      debugPrint('senderId : ${o.messagingSenderId}');
      debugPrint('token    : $token');
    } catch (e) {
      debugPrint('[FCM] debug token dump failed: $e');
    }

    // Cold-start notification routing is mobile-only.
    if (!kIsWeb) {
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        NotificationNavigator.hold(_toPayload(initial));
      } else {
        final localLaunch = await LocalNotificationsService.getLaunchPayload();
        if (localLaunch != null) {
          NotificationNavigator.hold(localLaunch);
        }
      }
    }

    _tokenSub = messaging.onTokenRefresh.listen((token) {
      _lastToken = token;
      unawaited(_syncToken(token));
    });

    try {
      final token = await _readFcmToken();
      _lastToken = token;
      if (token != null) {
        await _syncToken(token);
      }
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
    }
  }

  Future<String?> _readFcmToken() async {
    final messaging = _messaging;
    if (messaging == null) return null;
    // Mobile: plain getToken() — identical to prior app behavior.
    if (!kIsWeb) {
      return messaging.getToken();
    }
    const vapid = String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');
    if (vapid.isEmpty) return messaging.getToken();
    return messaging.getToken(vapidKey: vapid);
  }

  Future<void> _requestPermission() async {
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );
      debugPrint('[FCM] permission: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('[FCM] permission request failed: $e');
    }
  }

  /// Call after login / when session is confirmed so backend can map token→user.
  Future<void> registerTokenForSession() async {
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      final token = _lastToken ?? await _readFcmToken();
      if (token == null) return;
      _lastToken = token;
      await _syncToken(token);
    } catch (e) {
      debugPrint('[FCM] registerTokenForSession failed: $e');
    }
  }

  /// Call on logout so the device stops receiving user-bound pushes.
  Future<void> unregisterForSession() async {
    final token = _lastToken;
    if (token == null || token.isEmpty) return;
    if (!getIt.isRegistered<PushTokenApi>()) return;
    try {
      await getIt<PushTokenApi>().unregisterToken(token: token);
    } catch (e) {
      debugPrint('[FCM] unregister failed: $e');
    }
  }

  Future<void> _syncToken(String token) async {
    if (!getIt.isRegistered<SecureStorage>()) return;
    final hasToken = await getIt<SecureStorage>().hasToken;
    if (!hasToken) {
      debugPrint('[FCM] skip token sync — not authenticated');
      return;
    }
    if (!getIt.isRegistered<PushTokenApi>()) return;

    try {
      final deviceId = await getIt<DeviceIdProvider>().get();
      await getIt<PushTokenApi>().registerToken(
        deviceId: deviceId,
        token: token,
        platform: _platform,
      );
      debugPrint('[FCM] token registered ($_platform, device=$deviceId)');
    } catch (e) {
      debugPrint('[FCM] token sync failed: $e');
    }
  }

  void _onForeground(RemoteMessage message) {
    final payload = _toPayload(message);
    if (kIsWeb) {
      debugPrint('[FCM] web foreground: ${payload.title ?? payload.type}');
      return;
    }
    unawaited(LocalNotificationsService.showFromPush(payload));
  }

  void _onOpened(RemoteMessage message) {
    unawaited(NotificationNavigator.open(_toPayload(message)));
  }

  static PushPayload _toPayload(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    final n = message.notification;
    if (n != null) {
      data.putIfAbsent('title', () => n.title ?? '');
      data.putIfAbsent('body', () => n.body ?? '');
      data.putIfAbsent('message', () => n.body ?? '');
    }
    return PushPayload.fromMap(data);
  }

  Future<void> dispose() async {
    await _tokenSub?.cancel();
    await _openSub?.cancel();
    await _foregroundSub?.cancel();
    _started = false;
  }
}
