import 'dart:io';

/// Milliseconds for a TCP connect to [host]:[port], DNS lookup excluded.
/// null when the host doesn't resolve or the port doesn't answer.
Future<int?> tcpPing(String host, int port, {Duration timeout = const Duration(seconds: 4)}) async {
  try {
    final addresses = await InternetAddress.lookup(host).timeout(timeout);
    if (addresses.isEmpty) return null;
    final watch = Stopwatch()..start();
    final socket = await Socket.connect(addresses.first, port, timeout: timeout);
    watch.stop();
    socket.destroy();
    final ms = watch.elapsedMilliseconds;
    return ms < 1 ? 1 : ms;
  } catch (_) {
    return null;
  }
}
