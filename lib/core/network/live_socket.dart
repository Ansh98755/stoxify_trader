import 'live_socket_stub.dart'
    if (dart.library.io) 'live_socket_io.dart'
    if (dart.library.html) 'live_socket_web.dart';

/// Thin socket abstraction so mobile keeps `dart:io` WebSocket behavior and
/// web uses browser WebSockets — shared reconnect/ping lives in WebSocketService.
abstract class LiveSocket {
  Stream<dynamic> get stream;

  void add(String data);

  Future<void> close();

  bool get isOpen;
}

Future<LiveSocket> connectLiveSocket(
  String url, {
  Duration timeout = const Duration(seconds: 10),
}) =>
    platformConnectLiveSocket(url, timeout: timeout);
