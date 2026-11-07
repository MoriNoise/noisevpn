import 'vpn_backend.dart';
import 'windows_tun_stub.dart' if (dart.library.io) 'windows_tun_io.dart' as impl;

/// The fast Windows TUN engine: Xray + sing-box run from the app's own
/// `xray\` folder (fixed paths, so antivirus scans them once), sing-box owns
/// the Wintun adapter. Null where it can't run (not Windows, files missing).
abstract interface class WindowsTunEngine {
  static WindowsTunEngine? create() => impl.createWindowsTunEngine();

  Stream<VpnStatusEvent> get status;

  /// A session is up (both processes alive).
  bool get isActive;

  /// Throws [VpnEngineException] when it can't start.
  Future<void> start({
    required String config,
    required List<String> bypassSubnets,
    String? dnsServer,
  });

  Future<void> stop();

  /// Delay in ms of a real request through the running tunnel.
  Future<int?> connectedDelay(String url);

  /// Kills processes a crashed earlier run left behind.
  Future<void> cleanupStale();

  /// Recent engine events and process output, for Diagnostics.
  String get log;
}
