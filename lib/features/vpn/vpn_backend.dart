import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vless/flutter_vless.dart' show VlessOptions;

import '../../core/config/app_config.dart';
import '../servers/server_models.dart';
import 'config_tweaks.dart';
import 'flutter_vless_backend.dart';
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

/// Session options from Settings → Connection.
@immutable
class VpnStartOptions {
  const VpnStartOptions({
    this.proxyOnly = false,
    this.socksPort = 8142,
    this.blockedApps = const [],
    this.bypassSubnets = const [],
    this.dnsThroughTunnel = true,
    this.tweaks = const ConfigTweaks(),
  });

  final bool proxyOnly;
  final int socksPort;

  /// Android packages that skip the tunnel.
  final List<String> blockedApps;

  /// System-level bypass (macOS/Windows direct rules). Never sent on iOS or
  /// Android, which reject it; there it becomes a [tweaks] rule.
  final List<String> bypassSubnets;
  final bool dnsThroughTunnel;

  /// Edits to the Xray config itself (DNS, routing rules, fragment).
  final ConfigTweaks tweaks;
}

/// What the loaded native engine supports, from flutter_vless's
/// getCapabilities(). Settings only offers what is really there.
@immutable
class EngineCapabilities {
  const EngineCapabilities({
    this.quickAccess = false,
    this.addQuickTile = false,
    this.customReconnect = false,
    this.onDemand = false,
    this.alwaysOn = false,
    this.alwaysOnEnabled = false,
    this.lockdownEnabled = false,
    this.killSwitch = false,
  });

  /// A quick control (tile, menu bar, tray, Control Center) can be enabled.
  final bool quickAccess;

  /// Android 13+ can show the "Add tile" system dialog.
  final bool addQuickTile;
  final bool customReconnect;
  final bool onDemand;

  /// Android's Always-on state can be read and required.
  final bool alwaysOn;
  final bool alwaysOnEnabled;
  final bool lockdownEnabled;
  final bool killSwitch;
}

enum QuickTileResult { added, alreadyAdded, declined, unsupported }

/// Why the engine refused a request, from flutter_vless's error codes.
enum VpnEngineError {
  /// A newer start or a stop replaced this request. Not an error.
  cancelled,

  /// The config's routing can't be used on this platform.
  routing,

  /// Xray rejected the config.
  config,

  /// Android "Always-on VPN" is required by Settings but isn't set.
  alwaysOnRequired,

  /// The system Always-on VPN owns the session; stop it in system settings.
  alwaysOnManaged,

  /// iOS/macOS Keychain sharing between the app and the tunnel isn't set up.
  keychain,
  other,
}

class VpnEngineException implements Exception {
  const VpnEngineException(this.error, [this.detail]);

  final VpnEngineError error;
  final String? detail;

  @override
  String toString() => 'VpnEngineException(${error.name}${detail == null ? '' : ': $detail'})';
}

/// Everything the app needs from a VPN engine. The UI never touches
/// flutter_vless directly.
abstract interface class VpnBackend {
  /// False where flutter_vless has no native backend (Linux, web).
  bool get isSupported;

  Stream<VpnStatusEvent> get status;

  /// Engine options (notification, quick access, reconnect, protection,
  /// diagnostics). Applied at the next initialization.
  void setOptions(VlessOptions options);

  /// Set when the engine refused the chosen options and started with the
  /// defaults instead.
  String? get optionsError;

  Future<void> ensureInitialized();

  Future<bool> requestPermission();

  Future<void> start({
    required String remark,
    required String config,
    required String disconnectLabel,
    VpnStartOptions options = const VpnStartOptions(),
  });

  Future<void> stop();

  /// Whether a session is really running right now, independent of the
  /// status stream. null when the platform can't tell.
  Future<bool?> isSessionAlive();

  /// Delay in ms of a real request through [server]'s own config
  /// (Xray + the server's protocol + an HTTPS request to a 204 endpoint), or
  /// null when the server didn't answer.
  Future<int?> delay(VpnServer server);

  /// Delay in ms through the running session, or null.
  Future<int?> connectedDelay();

  Future<EngineCapabilities?> capabilities();

  Future<QuickTileResult> addQuickTile();

  Future<void> clearQuickAccess();

  Future<String?> coreVersion();

  /// Privacy-filtered native log (no configs or credentials).
  Future<String> diagnostics();

  void dispose();
}

final vpnBackendProvider = Provider<VpnBackend>((ref) {
  final VpnBackend backend = AppConfig.vpnSupported ? FlutterVlessBackend() : UnsupportedVpnBackend();
  ref.onDispose(backend.dispose);
  return backend;
});
