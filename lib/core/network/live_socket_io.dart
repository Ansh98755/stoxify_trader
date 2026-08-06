import 'dart:async';
import 'dart:io';

import 'live_socket.dart';

/// Mobile path — same API as prior WebSocket.connect usage.
Future<LiveSocket> platformConnectLiveSocket(
  String url, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final socket = await WebSocket.connect(url).timeout(timeout);
  return _IoLiveSocket(socket);
}

class _IoLiveSocket implements LiveSocket {
  _IoLiveSocket(this._socket);

  final WebSocket _socket;

  @override
  Stream<dynamic> get stream => _socket;

  @override
  void add(String data) => _socket.add(data);

  @override
  Future<void> close() => _socket.close();

  @override
  bool get isOpen => _socket.readyState == WebSocket.open;
}
