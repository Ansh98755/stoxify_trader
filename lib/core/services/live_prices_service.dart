import 'dart:async';

import '../../features/home/data/datasources/market_data_remote_data_source.dart';
import '../network/websocket_service.dart';

const _kPollInterval = Duration(seconds: 5);

/// Session-wide LTP cache merged from WebSocket updates and HTTP polling.
class LivePricesService {
  LivePricesService({
    required WebSocketService webSocket,
    required MarketDataRemoteDataSource marketData,
  })  : _webSocket = webSocket,
        _marketData = marketData;

  final WebSocketService _webSocket;
  final MarketDataRemoteDataSource _marketData;

  final _controller = StreamController<Map<String, double>>.broadcast();
  final Map<String, double> _current = {};
  final Set<String> _symbols = {};

  StreamSubscription<Map<String, double>>? _wsSubscription;
  Timer? _timer;
  bool _started = false;

  Stream<Map<String, double>> get pricesStream => _controller.stream;

  Map<String, double> get current => Map.unmodifiable(_current);

  void start() {
    if (_started) return;
    _started = true;

    _wsSubscription = _webSocket.priceUpdates.listen((updatedPrices) {
      if (updatedPrices.isEmpty) return;
      _current.addAll(updatedPrices);
      _controller.add(Map<String, double>.from(_current));
    });

    // Always poll as a backup — WS can be "open" without regular price pushes.
    _startOrUpdateTimer();
  }

  /// Register [symbols] to poll. Previous symbols are replaced.
  void track(Iterable<String> symbols) {
    final fresh = symbols.where((s) => s.isNotEmpty).toSet();
    final changed =
        fresh.length != _symbols.length || !fresh.containsAll(_symbols);
    if (!changed) {
      if (_started && _symbols.isNotEmpty) _poll();
      return;
    }

    _symbols
      ..clear()
      ..addAll(fresh);

    _startOrUpdateTimer();
    _poll();
  }

  /// Adds symbols without replacing those already tracked by another screen.
  void trackAdditional(Iterable<String> symbols) {
    final Set<String> additional =
        symbols.where((symbol) => symbol.isNotEmpty).toSet();
    if (additional.isEmpty || _symbols.containsAll(additional)) return;

    _symbols.addAll(additional);
    _startOrUpdateTimer();
    _poll();
  }

  void _startOrUpdateTimer() {
    _timer?.cancel();
    if (_symbols.isEmpty) return;
    _timer = Timer.periodic(_kPollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    if (_symbols.isEmpty) return;

    final results = await _marketData.prices(_symbols.toList());
    if (results.isEmpty) return;

    _current.addAll(results);
    // Always push — Home must refresh LTP as soon as a tick arrives.
    _controller.add(Map<String, double>.from(_current));
  }

  void dispose() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _timer?.cancel();
    _timer = null;
    _started = false;
    _controller.close();
  }

  /// Clears account/session-specific subscriptions without closing the service.
  Future<void> resetSession() async {
    await _wsSubscription?.cancel();
    _wsSubscription = null;
    _timer?.cancel();
    _timer = null;
    _started = false;
    _current.clear();
    _symbols.clear();
  }
}
