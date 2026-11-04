import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vless/flutter_vless.dart';

import '../../core/config/app_config.dart';
import '../servers/server_models.dart';
import 'vpn_backend.dart';

/// flutter_vless 1.1.6 (Xray core) on Android, iOS, macOS and Windows.
class FlutterVlessBackend implements VpnBackend {
  FlutterVlessBackend() {
    _vless = FlutterVless(onStatusChanged: _onStatus);
  }

  late final FlutterVless _vless;
  final _status = StreamController<VpnStatusEvent>.broadcast();
  Future<void>? _init;

  @override
  bool get isSupported => true;

  @override
  Stream<VpnStatusEvent> get status => _status.stream;

  void _onStatus(VlessStatus s) {
    final phase = switch (s.connectionState) {
      VlessConnectionState.connected => VpnPhase.connected,
      VlessConnectionState.connecting => VpnPhase.connecting,
      VlessConnectionState.disconnected => VpnPhase.disconnected,
      VlessConnectionState.disconnecting => VpnPhase.disconnecting,
      VlessConnectionState.unknown => null,
    };
    if (phase == null || _status.isClosed) return;
    _status.add(VpnStatusEvent(
      phase: phase,
      duration: s.duration,
      uploadSpeed: s.uploadSpeed,
      downloadSpeed: s.downloadSpeed,
      upload: s.upload,
      download: s.download,
    ));
  }

  @override
  Future<void> ensureInitialized() => _init ??= _initialize();

  Future<void> _initialize() async {
    try {
      await _vless.initializeVless(
        providerBundleIdentifier: AppConfig.appleBundleId,
        groupIdentifier: AppConfig.appleGroupId,
      );
    } catch (_) {
      _init = null; // allow a retry on the next attempt
      rethrow;
    }
  }

  @override
  Future<bool> requestPermission() => _vless.requestPermission();

  @override
  Future<void> start({
    required String remark,
    required String config,
    required String disconnectLabel,
    VpnStartOptions options = const VpnStartOptions(),
  }) {
    return _vless.startVless(
      remark: remark,
      config: options.proxyOnly ? _withSocksPort(config, options.socksPort) : config,
      proxyOnly: options.proxyOnly,
      blockedApps: options.proxyOnly || options.blockedApps.isEmpty ? null : options.blockedApps,
      bypassSubnets: options.proxyOnly || options.bypassSubnets.isEmpty ? null : options.bypassSubnets,
      // proxy = system DNS goes through the tunnel instead of the local network.
      androidDnsPolicy: !options.proxyOnly && options.dnsThroughTunnel ? AndroidDnsPolicy.proxy : AndroidDnsPolicy.config,
      notificationDisconnectButtonName: disconnectLabel,
    );
  }

  /// Proxy-only mode serves the config's SOCKS inbound to other apps, so
  /// that inbound gets the port chosen in Settings.
  static String _withSocksPort(String config, int port) {
    try {
      final json = jsonDecode(config) as Map<String, dynamic>;
      for (final inbound in (json['inbounds'] as List? ?? const [])) {
        if (inbound is Map && inbound['protocol'] == 'socks') inbound['port'] = port;
      }
      return jsonEncode(json);
    } catch (_) {
      return config;
    }
  }

  @override
  Future<void> stop() => _vless.stopVless();

  static const _native = MethodChannel('noisevpn/native');

  @override
  Future<bool?> isSessionAlive() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await _native.invokeMethod<bool>('vpnServiceRunning');
    } catch (_) {
      return null;
    }
  }

  @override
  /// Real delay through Xray with the server's own config.
  Future<int?> delay(VpnServer server) async {
    try {
      await ensureInitialized();
      final ms = await _vless.getServerDelay(config: server.config, url: AppConfig.pingUrl);
      return ms > 0 ? ms : null;
    } catch (e) {
      debugPrint('ping failed: $e');
      return null;
    }
  }

  @override
  void dispose() => _status.close();
}
