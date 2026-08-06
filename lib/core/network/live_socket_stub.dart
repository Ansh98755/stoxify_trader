import 'live_socket.dart';

Future<LiveSocket> platformConnectLiveSocket(
  String url, {
  Duration timeout = const Duration(seconds: 10),
}) {
  throw UnsupportedError('Live socket not available on this platform');
}
