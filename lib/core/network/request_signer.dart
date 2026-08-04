import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pointycastle/export.dart';

abstract class RequestSigner {
  Future<Map<String, String>> buildSignatureHeaders({
    required String method,
    required String path,
    required String body,
    required String deviceId,
  });
}

/// ECDSA P-256 request signer.
///
/// Key resolution order:
/// 1. `--dart-define=ECDSA_PRIVATE_KEY_PEM=...`
///    - plain PEM, or base64 / URL-safe base64 of the PEM (Vercel-friendly)
/// 2. Bundled `assets/dev/ecdsa_private.pem` when not in release, or when
///    `--dart-define=ALLOW_DEV_SIGNER=true`
class EcdsaRequestSigner implements RequestSigner {
  EcdsaRequestSigner._(this._privateKey, this.keyVersion);

  final ECPrivateKey _privateKey;
  final String keyVersion;
  final Random _rng = Random.secure();

  static const _devKeyAsset = 'assets/dev/ecdsa_private.pem';
  static const _envKey = String.fromEnvironment('ECDSA_PRIVATE_KEY_PEM');
  static const _allowDevSignerInRelease =
      bool.fromEnvironment('ALLOW_DEV_SIGNER');

  /// Prefer [load]; kept for callers that still import the old name.
  static Future<EcdsaRequestSigner> loadDev({String keyVersion = 'v1.0'}) =>
      load(keyVersion: keyVersion);

  static Future<EcdsaRequestSigner> load({String keyVersion = 'v1.0'}) async {
    final pem = await _resolvePem();
    if (pem == null || pem.trim().isEmpty) {
      throw StateError(
        'No ECDSA signing key available. '
        'Set ECDSA_PRIVATE_KEY_PEM (base64 or PEM) on the release build, '
        'or ALLOW_DEV_SIGNER=true for web CI.',
      );
    }
    final key = CryptoUtils.ecPrivateKeyFromPem(pem);
    return EcdsaRequestSigner._(key, keyVersion);
  }

  static Future<String?> _resolvePem() async {
    if (_envKey.isNotEmpty) {
      return _decodeEnvKey(_envKey);
    }
    if (kReleaseMode && !_allowDevSignerInRelease) {
      return null;
    }
    return rootBundle.loadString(_devKeyAsset);
  }

  /// Accepts raw PEM or base64(PEM) as used by Vercel `dart-define`.
  static String _decodeEnvKey(String raw) {
    final cleaned = raw.trim();

    // 1) Already a PEM document
    if (_looksLikePem(cleaned)) {
      return _normalizeNewlines(cleaned);
    }

    // 2) Literal "\n" in env var body with PEM markers after expand
    final unescaped = _normalizeNewlines(cleaned);
    if (_looksLikePem(unescaped)) return unescaped;

    // 3) Standard base64 of the whole PEM
    final asB64 = _tryBase64ToPem(cleaned);
    if (asB64 != null) return asB64;

    // 4) URL-safe base64
    final urlSafe = cleaned
        .replaceAll('-', '+')
        .replaceAll('_', '/');
    final padded = urlSafe.padRight(
      urlSafe.length + ((4 - urlSafe.length % 4) % 4),
      '=',
    );
    final asUrlB64 = _tryBase64ToPem(padded);
    if (asUrlB64 != null) return asUrlB64;

    // Last resort: hand to PEM parser (may throw a clearer error)
    return unescaped;
  }

  static String? _tryBase64ToPem(String input) {
    try {
      // strip whitespace/newlines from base64 wrappers
      final compact = input.replaceAll(RegExp(r'\s+'), '');
      final decoded = utf8.decode(base64.decode(compact));
      if (_looksLikePem(decoded)) return decoded.trim();
    } catch (_) {
      // not valid base64
    }
    return null;
  }

  static bool _looksLikePem(String value) =>
      value.contains('BEGIN') && value.contains('PRIVATE KEY');

  static String _normalizeNewlines(String value) {
    var s = value.trim();
    if ((s.startsWith('"') && s.endsWith('"')) ||
        (s.startsWith("'") && s.endsWith("'"))) {
      s = s.substring(1, s.length - 1).trim();
    }
    if (s.contains(r'\n') && !s.contains('\n')) {
      s = s.replaceAll(r'\n', '\n');
    }
    return s;
  }

  @override
  Future<Map<String, String>> buildSignatureHeaders({
    required String method,
    required String path,
    required String body,
    required String deviceId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final nonce = _nonceHex();
    final message = '$method|$path|$body|$timestamp|$nonce|$deviceId';
    final signature = _sign(message);

    return <String, String>{
      'X-Timestamp': timestamp,
      'X-Device-ID': deviceId,
      'X-Nonce': nonce,
      'X-Signature': signature,
      'X-Key-Version': keyVersion,
    };
  }

  String _sign(String message) {
    final signer = Signer('SHA-256/DET-ECDSA') as ECDSASigner;
    signer.init(true, PrivateKeyParameter<ECPrivateKey>(_privateKey));
    final sig = signer.generateSignature(
      Uint8List.fromList(utf8.encode(message)),
    ) as ECSignature;

    final seq = ASN1Sequence()
      ..add(ASN1Integer(sig.r))
      ..add(ASN1Integer(sig.s));
    return base64.encode(seq.encodedBytes);
  }

  String _nonceHex() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
