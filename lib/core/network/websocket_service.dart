import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../storage/secure_storage.dart';
import 'api_client.dart';
import 'live_socket.dart';

/// Keeps a single live-updates socket open for the app's lifetime.
///
/// Mobile still uses `dart:io` WebSocket (see [live_socket_io.dart]).
/// Web uses browser sockets (see [live_socket_web.dart]).
class WebSocketService with WidgetsBindingObserver {
  WebSocketService({
    required this.authRepository,
    required this.storage,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  final AuthRepository authRepository;
  final SecureStorage storage;

  LiveSocket? _socket;
  StreamSubscription<dynamic>? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  bool _connecting = false;
  int _reconnectAttempts = 0;

  static const _baseReconnectInterval = Duration(seconds: 3);
  static const _maxReconnectInterval = Duration(seconds: 30);

  final _priceController = StreamController<Map<String, double>>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, double>> get priceUpdates => _priceController.stream;
  Stream<Map<String, dynamic>> get notificationUpdates =>
      _notificationController.stream;

  bool get isConnected => _socket != null && _socket!.isOpen;

  Future<void> connect() async {
    if (_connecting || isConnected || _isDisposed) return;
    _connecting = true;

    try {
      final token = await storage.read(SecureStorage.accessToken);
      if (token == null || token.isEmpty) {
        _connecting = false;
        return;
      }

      final channelId = await authRepository.requestWsChannel();

      final base = apiBaseUrl
          .replaceAll('https://', 'wss://')
          .replaceAll('http://', 'ws://');
      final wsUrl = '$base/ws/?channel_id=$channelId';

      debugPrint('[WS] Connecting to $wsUrl');
      _socket = await connectLiveSocket(
        wsUrl,
        timeout: const Duration(seconds: 10),
      );
      _reconnectAttempts = 0;
      _connecting = false;

      debugPrint('[WS] *********** Connected successfully *************');
      _startPing();

      _sub = _socket!.stream.listen(
        _onMessage,
        onDone: _onClose,
        onError: _onError,
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[WS] Connection error: $e');
      _connecting = false;
      // Match prior mobile behavior: drop handle and reconnect (do not force-close twice).
      unawaited(_sub?.cancel());
      _sub = null;
      _socket = null;
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic rawMessage) {
    try {
      final msg = jsonDecode(rawMessage.toString());
      final type = msg['type'];

      if (type == 'price_update') {
        final pricesRaw = msg['prices'];
        if (pricesRaw is Map) {
          final prices = <String, double>{};
          pricesRaw.forEach((k, v) {
            if (k is String && v is num) {
              prices[k] = v.toDouble();
            }
          });
          if (prices.isNotEmpty) {
            _priceController.add(prices);
          }
        }
      } else if (type == 'NOTIFICATION_NEW') {
        final data = msg['data'];
        if (data is Map) {
          _notificationController.add(data.cast<String, dynamic>());
        }
      }
    } catch (e) {
      debugPrint('[WS] Error parsing message: $e');
    }
  }

  void _onClose() {
    debugPrint('[WS] Connection closed');
    _cleanup();
    _scheduleReconnect();
  }

  void _onError(dynamic err) {
    debugPrint('[WS] Error: $err');
    _cleanup();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isDisposed || _connecting) return;
    _reconnectAttempts++;
    final backoffSeconds = _baseReconnectInterval.inSeconds *
        pow(2, (_reconnectAttempts - 1).clamp(0, 10));
    final delay = Duration(
      seconds: min(backoffSeconds.toInt(), _maxReconnectInterval.inSeconds),
    );
    debugPrint(
      '[WS] Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s',
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, connect);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !isConnected) {
      debugPrint('[WS] App resumed — forcing reconnect');
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      connect();
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (isConnected) {
        _socket!.add(jsonEncode({'type': 'ping'}));
      }
    });
  }

  void _cleanup() {
    _pingTimer?.cancel();
    _pingTimer = null;
    unawaited(_sub?.cancel());
    _sub = null;
    _socket = null;
  }

  void disconnect() {
    final socket = _socket;
    _cleanup();
    unawaited(socket?.close());
  }

  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    disconnect();
    _priceController.close();
    _notificationController.close();
  }
}
