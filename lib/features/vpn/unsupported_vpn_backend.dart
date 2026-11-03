import 'vpn_backend.dart';
import '../servers/server_models.dart';

/// Linux and web: flutter_vless has no native backend there, so the app
/// can neither open a tunnel nor measure a real delay. Nothing is faked:
/// the server list is the real subscription and ping is simply not shown.
/// (A TCP handshake only proves a port is open, not that the config works.)
class UnsupportedVpnBackend implements VpnBackend {
  @override
  bool get isSupported => false;

  @override
  Stream<VpnStatusEvent> get status => const Stream.empty();

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> start({
    required String remark,
    required String config,
    required String disconnectLabel,
  }) {
    throw UnsupportedError('flutter_vless has no backend on this platform');
  }

  @override
  Future<void> stop() async {}

  @override
  Future<int?> delay(VpnServer server) async => null;

  @override
  void dispose() {}
}
