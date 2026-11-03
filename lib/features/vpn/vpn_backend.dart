import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import 'flutter_vless_backend.dart';
import '../servers/server_models.dart';
import 'unsupported_vpn_backend.dart';

enum VpnPhase { disconnected, connecting, connected, disconnecting }

@immutable
class VpnStatusEvent {
  const VpnStatusEvent({
    required this.phase,
    this.duration = 0,
    this.uploadSpeed = 0,
    this.downloadSpeed = 0,
    this.upload = 0,
    this.download = 0,
  });

  final VpnPhase phase;
  final int duration;
  final int uploadSpeed;
  final int downloadSpeed;
  final int upload;
  final int download;
}

/// Everything the app needs from a VPN engine. The UI never touches
/// flutter_vless directly.
abstract interface class VpnBackend {
  /// False where flutter_vless has no native backend (Linux, web).
  bool get isSupported;

  Stream<VpnStatusEvent> get status;

  Future<void> ensureInitialized();

  Future<bool> requestPermission();

  Future<void> start({
    required String remark,
    required String config,
    required String disconnectLabel,
  });

  Future<void> stop();

  /// Delay in ms of a real request through [server]'s own config
  /// (Xray + VLESS/TLS + an HTTPS HEAD to a 204 endpoint), or null when the
  /// server didn't answer.
  Future<int?> delay(VpnServer server);

  void dispose();
}

final vpnBackendProvider = Provider<VpnBackend>((ref) {
  final VpnBackend backend = AppConfig.vpnSupported ? FlutterVlessBackend() : UnsupportedVpnBackend();
  ref.onDispose(backend.dispose);
  return backend;
});
