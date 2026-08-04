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
/// Resolution order:
/// 1. `--dart-define=ECDSA_PRIVATE_KEY_PEM=...` (production / CI)
/// 2. Bundled `assets/dev/ecdsa_private.pem` (debug, or release with
///    `--dart-define=ALLOW_DEV_SIGNER=true`)
class EcdsaRequestSigner implements RequestSigner {
  EcdsaRequestSigner._(this._privateKey, this.keyVersion);

  final ECPrivateKey _privateKey;
  final String keyVersion;
  final Random _rng = Random.secure();

  static const _devKeyAsset = 'assets/dev/ecdsa_private.pem';
  static const _envPem = String.fromEnvironment('ECDSA_PRIVATE_KEY_PEM');
  static const _allowDevSignerInRelease =
      bool.fromEnvironment('ALLOW_DEV_SIGNER');

  static Future<EcdsaRequestSigner> loadDev({String keyVersion = 'v1.0'}) async {
    final String? pem = await _resolvePem();
    if (pem == null || pem.trim().isEmpty) {
      throw StateError(
        'No ECDSA signing key available. For release/web production, pass '
        '--dart-define=ECDSA_PRIVATE_KEY_PEM=... (or ALLOW_DEV_SIGNER=true '
        'to use the bundled dev key).',
      );
    }
    final key = CryptoUtils.ecPrivateKeyFromPem(_normalizePem(pem));
    return EcdsaRequestSigner._(key, keyVersion);
  }

  /// Prefer the compile-time env PEM; fall back to the bundled dev asset when
  /// allowed.
  static Future<String?> _resolvePem() async {
    if (_envPem.isNotEmpty) return _envPem;

    if (kReleaseMode && !_allowDevSignerInRelease) {
      return null;
    }
    return rootBundle.loadString(_devKeyAsset);
  }

  /// Env vars often store multi-line PEMs with literal `\n` sequences.
  static String _normalizePem(String pem) {
    var value = pem.trim();
    if (value.contains(r'\n') && !value.contains('\n')) {
      value = value.replaceAll(r'\n', '\n');
    }
    // Strip surrounding quotes if the whole PEM was wrapped.
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1).trim();
      if (value.contains(r'\n') && !value.contains('\n')) {
        value = value.replaceAll(r'\n', '\n');
      }
    }
    return value;
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
