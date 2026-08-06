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
/// Release / Vercel: PEM comes from
/// `--dart-define=ECDSA_PRIVATE_KEY_PEM=<base64-encoded PEM>`
/// (same var already set in Vercel project settings).
///
/// Debug: falls back to bundled `assets/dev/ecdsa_private.pem`.
class EcdsaRequestSigner implements RequestSigner {
  EcdsaRequestSigner._(this._privateKey, this.keyVersion);

  final ECPrivateKey _privateKey;
  final String keyVersion;
  final Random _rng = Random.secure();

  static const _devKeyAsset = 'assets/dev/ecdsa_private.pem';
  static const _injectedKeyBase64 =
      String.fromEnvironment('ECDSA_PRIVATE_KEY_PEM');
  static const _allowDevSignerInRelease =
      bool.fromEnvironment('ALLOW_DEV_SIGNER');

  /// Loads the signer (name kept for DI).
  static Future<EcdsaRequestSigner> loadDev({String keyVersion = 'v1.0'}) async {
    final String pem;

    if (_injectedKeyBase64.isNotEmpty) {
      // Production: base64-encoded PEM from Vercel env / dart-define.
      final compact = _injectedKeyBase64.replaceAll(RegExp(r'\s+'), '');
      pem = utf8.decode(base64.decode(compact));
    } else if (!kReleaseMode || _allowDevSignerInRelease) {
      // Local debug (or explicit allow in release).
      pem = await rootBundle.loadString(_devKeyAsset);
    } else {
      // This throw is what caused the blank production screen when the
      // env key was never wired into the app despite being on Vercel.
      throw StateError(
        'No ECDSA signing key available. '
        'Set ECDSA_PRIVATE_KEY_PEM (base64 of the PEM) for release builds.',
      );
    }

    final key = CryptoUtils.ecPrivateKeyFromPem(pem);
    return EcdsaRequestSigner._(key, keyVersion);
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
