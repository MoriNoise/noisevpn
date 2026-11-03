// Real TCP handshake time to a server. dart:io isn't available on web,
// so web gets a stub that reports no result.
export 'tcp_ping_stub.dart' if (dart.library.io) 'tcp_ping_io.dart';
