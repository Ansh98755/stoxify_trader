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
/// In release / CI builds the PEM is injected at compile time via:
///   --dart-define=ECDSA_PRIVATE_KEY_PEM=<url-safe-base64-encoded PEM>
///
/// In debug builds it falls back to the bundled `assets/dev/ecdsa_private.pem`.
class EcdsaRequestSigner implements RequestSigner {
  EcdsaRequestSigner._(this._privateKey, this.keyVersion);

  final ECPrivateKey _privateKey;
  final String keyVersion;
  final Random _rng = Random.secure();

  // Injected at compile time via --dart-define.
  // Store as base64 to avoid newline / quote issues in shell.
  static const _injectedKeyBase64 = String.fromEnvironment('ECDSA_PRIVATE_KEY_PEM');
  static const _devKeyAsset = 'assets/dev/ecdsa_private.pem';

  /// Loads the signer from the injected dart-define key in release builds,
  /// or from the bundled asset in debug builds.
  static Future<EcdsaRequestSigner> load({String keyVersion = 'v1.0'}) async {
    String pem;

    if (_injectedKeyBase64.isNotEmpty) {
      // Decode the base64-encoded PEM injected via --dart-define
      pem = utf8.decode(base64.decode(_injectedKeyBase64));
    } else if (!kReleaseMode) {
      // Debug/profile only — load from bundled asset
      pem = await rootBundle.loadString(_devKeyAsset);
    } else {
      throw StateError(
        'No ECDSA signing key available. '
        'Set the ECDSA_PRIVATE_KEY_PEM dart-define in your release build.',
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
