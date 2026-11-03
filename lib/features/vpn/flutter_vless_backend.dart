import 'dart:async';

import 'package:flutter/foundation.dart';
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
  }) {
    return _vless.startVless(
      remark: remark,
      config: config,
      // Send system DNS through the tunnel instead of the local network.
      androidDnsPolicy: AndroidDnsPolicy.proxy,
      notificationDisconnectButtonName: disconnectLabel,
    );
  }

  @override
  Future<void> stop() => _vless.stopVless();

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
