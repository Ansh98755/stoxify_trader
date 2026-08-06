// File generated for Firebase multi-platform bootstrap.
// Mobile still prefers native google-services / GoogleService-Info when present.
// Web requires [web] options (override via --dart-define for production secrets).
//
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for each platform.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  /// Web Firebase app — values can be overridden at build time:
  /// `--dart-define=FIREBASE_WEB_API_KEY=...` etc.
  ///
  /// Defaults use stoxify-prod (Android project). Register a Web app in the
  /// Firebase console and set FIREBASE_WEB_APP_ID for production.
  static FirebaseOptions get web => FirebaseOptions(
        apiKey: const String.fromEnvironment(
          'FIREBASE_WEB_API_KEY',
          defaultValue: 'AIzaSyD0kWR9QjWWzFEBuCXfjqJATRi9YH0LwGs',
        ),
        appId: const String.fromEnvironment(
          'FIREBASE_WEB_APP_ID',
          defaultValue: '1:67935375432:web:0000000000000000000000',
        ),
        messagingSenderId: const String.fromEnvironment(
          'FIREBASE_WEB_MESSAGING_SENDER_ID',
          defaultValue: '67935375432',
        ),
        projectId: const String.fromEnvironment(
          'FIREBASE_WEB_PROJECT_ID',
          defaultValue: 'stoxify-prod',
        ),
        authDomain: const String.fromEnvironment(
          'FIREBASE_WEB_AUTH_DOMAIN',
          defaultValue: 'stoxify-prod.firebaseapp.com',
        ),
        storageBucket: const String.fromEnvironment(
          'FIREBASE_WEB_STORAGE_BUCKET',
          defaultValue: 'stoxify-prod.firebasestorage.app',
        ),
      );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD0kWR9QjWWzFEBuCXfjqJATRi9YH0LwGs',
    appId: '1:67935375432:android:138e60be6357637cc2887d',
    messagingSenderId: '67935375432',
    projectId: 'stoxify-prod',
    storageBucket: 'stoxify-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCvbbeB5kRKYE7Irx3fXERY2UBaV19GgGQ',
    appId: '1:729175739004:ios:de3bd87ebad6bd895597f9',
    messagingSenderId: '729175739004',
    projectId: 'stoxify-93c2e',
    storageBucket: 'stoxify-93c2e.firebasestorage.app',
    iosBundleId: 'in.stoxify.stoxify',
  );
}
