import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Outcome of a user- or app-triggered OTA check.
enum OtaCheckResult {
  /// No Shorebird engine (e.g. `flutter run` debug / non-shorebird build).
  unavailable,

  /// Already on latest patch.
  upToDate,

  /// A new patch was downloaded; restart the app to apply it.
  updateReady,

  /// Download/check failed.
  failed,
}

/// Wraps Shorebird OTA updates (code push).
///
/// Builds shipped with `shorebird release` also auto-check in the background.
/// This service adds explicit check + download + status for UI (settings).
class OtaUpdateService {
  OtaUpdateService._();

  static final OtaUpdateService instance = OtaUpdateService._();

  final ShorebirdUpdater _updater = ShorebirdUpdater();

  /// True only in Shorebird-enabled release/preview builds.
  bool get isAvailable => _updater.isAvailable;

  Future<int?> currentPatchNumber() async {
    if (!isAvailable) return null;
    try {
      final patch = await _updater.readCurrentPatch();
      return patch?.number;
    } catch (e) {
      debugPrint('[OTA] readCurrentPatch failed: $e');
      return null;
    }
  }

  /// Non-blocking entry point — safe to call after first frame / from settings.
  ///
  /// Does **not** block app startup. Download happens in the background;
  /// patches apply on the **next** cold start (Shorebird default).
  /// No-op on web (Shorebird is mobile/desktop only).
  Future<OtaCheckResult> checkAndDownload({bool silent = true}) async {
    if (kIsWeb || !isAvailable) {
      if (!silent && !kIsWeb) {
        debugPrint('[OTA] updater unavailable (use shorebird release builds)');
      }
      return OtaCheckResult.unavailable;
    }

    try {
      final status = await _updater.checkForUpdate();
      debugPrint('[OTA] checkForUpdate → $status');

      switch (status) {
        case UpdateStatus.upToDate:
          return OtaCheckResult.upToDate;
        case UpdateStatus.outdated:
          await _updater.update();
          debugPrint('[OTA] patch downloaded — restart app to apply');
          return OtaCheckResult.updateReady;
        case UpdateStatus.restartRequired:
          return OtaCheckResult.updateReady;
        case UpdateStatus.unavailable:
          return OtaCheckResult.unavailable;
      }
    } on UpdateException catch (e) {
      debugPrint('[OTA] update failed: ${e.message}');
      return OtaCheckResult.failed;
    } catch (e) {
      debugPrint('[OTA] check/download failed: $e');
      return OtaCheckResult.failed;
    }
  }
}
