import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Emits true when the device has any network interface (wifi / mobile / ethernet).
/// Emits false when all interfaces are gone.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onConnectivityChanged => _connectivity.onConnectivityChanged
      .map((results) => _hasConnection(results));

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  static bool _hasConnection(List<ConnectivityResult> results) {
    // Browser-only: avoid false offline overlays from flaky browser APIs.
    if (kIsWeb) {
      if (results.isEmpty) return true;
      return !results.every((r) => r == ConnectivityResult.none);
    }
    // Mobile path — identical to pre-web checks (no `other`).
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
  }
}
