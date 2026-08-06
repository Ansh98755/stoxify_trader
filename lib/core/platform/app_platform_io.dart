import 'dart:io' show Platform;

/// Mobile / desktop VM path — exact prior Platform checks.
bool get platformIsWeb => false;

String get platformDeviceType => Platform.isIOS ? 'IOS' : 'ANDROID';

String get platformDeviceName => 'StoXify ${Platform.operatingSystem}';

String get platformPushPlatform => Platform.isIOS ? 'ios' : 'android';

bool get platformIsAndroid => Platform.isAndroid;

bool get platformIsIOS => Platform.isIOS;
