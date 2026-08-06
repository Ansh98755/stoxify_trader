import 'package:web_socket_channel/web_socket_channel.dart';

import 'live_socket.dart';

/// Web-only browser socket.
Future<LiveSocket> platformConnectLiveSocket(
  String url, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final channel = WebSocketChannel.connect(Uri.parse(url));
  await channel.ready.timeout(timeout);
  return _WebLiveSocket(channel);
}

class _WebLiveSocket implements LiveSocket {
  _WebLiveSocket(this._channel);

  final WebSocketChannel _channel;
  bool _open = true;

  @override
  Stream<dynamic> get stream => _channel.stream.map((event) {
        return event;
      }).handleError((_) {
        _open = false;
      });

  @override
  void add(String data) => _channel.sink.add(data);

  @override
  Future<void> close() async {
    _open = false;
    await _channel.sink.close();
  }

  @override
  bool get isOpen => _open;
}
