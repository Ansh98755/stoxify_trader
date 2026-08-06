import 'app_platform_stub.dart'
    if (dart.library.io) 'app_platform_io.dart'
    if (dart.library.html) 'app_platform_web.dart';

/// Cross-platform device / OS labels. Mobile uses real `dart:io` Platform so
/// values stay identical to the pre-web codebase.
abstract final class AppPlatform {
  static bool get isWeb => platformIsWeb;

  /// Backend `device_type` (ANDROID | IOS | WEB).
  static String get deviceType => platformDeviceType;

  /// Human-readable device name for login payloads.
  static String get deviceName => platformDeviceName;

  /// FCM / push token platform field (lowercase).
  static String get pushPlatform => platformPushPlatform;

  static bool get isAndroid => platformIsAndroid;

  static bool get isIOS => platformIsIOS;
}
