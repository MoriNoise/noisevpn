import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vless/flutter_vless.dart';

import '../../core/config/app_config.dart';
import '../servers/server_models.dart';
import 'geo_assets.dart';
import 'vpn_backend.dart';

bool get _iOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// flutter_vless 1.1.7 (Xray core) on Android, iOS, macOS and Windows.
class FlutterVlessBackend implements VpnBackend {
  FlutterVlessBackend() {
    _vless = FlutterVless(onStatusChanged: _onStatus);
  }

  late FlutterVless _vless;
  final _status = StreamController<VpnStatusEvent>.broadcast();
  Future<void>? _init;

  VlessOptions _wanted = const VlessOptions();

  /// The options the engine was last initialized with ('' = none yet).
  String _initializedKey = '';
  String? _optionsError;

  @override
  bool get isSupported => true;

  @override
  Stream<VpnStatusEvent> get status => _status.stream;

  @override
  String? get optionsError => _optionsError;

  static String _key(VlessOptions o) {
    try {
      return jsonEncode(o.toMap());
    } catch (_) {
      return 'invalid';
    }
  }

  @override
  void setOptions(VlessOptions options) {
    _wanted = options;
    // Re-initialize on the next call when anything changed. flutter_vless
    // takes options at construction, so a new instance is created then.
    if (_key(options) != _initializedKey && _init != null) _init = null;
  }

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

  Future<void> _initWith(VlessOptions options) async {
    final vless = FlutterVless(onStatusChanged: _onStatus, options: options);
    await vless
        .initializeVless(
          providerBundleIdentifier: AppConfig.appleBundleId,
          groupIdentifier: AppConfig.appleGroupId,
          // iOS shares the profile's Keychain item with the tunnel through
          // the App Group (no separate keychain-access-groups entitlement).
          keychainAccessGroup: _iOS ? AppConfig.appleGroupId : null,
        )
        // A hung init would otherwise be cached and block every retry.
        .timeout(const Duration(seconds: 15));
    _vless = vless;
    _initializedKey = _key(options);
  }

  Future<void> _initialize() async {
    final wanted = _wanted;
    try {
      await _initWith(wanted);
      _optionsError = null;
    } on TimeoutException {
      _init = null; // allow a retry on the next attempt
      rethrow;
    } catch (e) {
      if (_key(wanted) == _key(const VlessOptions())) {
        _init = null;
        rethrow;
      }
      // The engine refused an option (an unsupported quick control, Android
      // too old for "require Always-on"…). Connecting still works with the
      // defaults; Settings shows the error.
      debugPrint('vpn options refused, using defaults: $e');
      try {
        await _initWith(const VlessOptions());
        _optionsError = e is PlatformException ? (e.message ?? e.code) : '$e';
      } catch (_) {
        _init = null;
        rethrow;
      }
    }
  }

  @override
  Future<bool> requestPermission() => _vless.requestPermission();

  /// flutter_vless error codes → app errors. Native messages are never shown.
  static VpnEngineException _map(PlatformException e) {
    if (e.code == 'VPN_START_CANCELLED') return const VpnEngineException(VpnEngineError.cancelled);
    if (e.code == 'ALWAYS_ON_MANAGED') return const VpnEngineException(VpnEngineError.alwaysOnManaged);
    if (e.code == 'VPN_KEYCHAIN_ERROR') return VpnEngineException(VpnEngineError.keychain, e.code);
    if (e.code.contains('ALWAYS_ON')) return VpnEngineException(VpnEngineError.alwaysOnRequired, e.code);
    final failure = VlessConfigurationFailure.fromDetails(e.details);
    if (e.code.contains('ROUTING') || failure?.stage == 'routing') {
      return VpnEngineException(VpnEngineError.routing, e.code);
    }
    if (failure != null) return VpnEngineException(VpnEngineError.config, failure.stage);
    return VpnEngineException(VpnEngineError.other, e.code);
  }

  @override
  Future<void> start({
    required String remark,
    required String config,
    required String disconnectLabel,
    VpnStartOptions options = const VpnStartOptions(),
  }) async {
    var prepared = options.proxyOnly ? _withSocksPort(config, options.socksPort) : config;
    prepared = options.tweaks.apply(prepared);
    // Only Windows and macOS take system bypass subnets (as direct rules
    // after flutter_vless's own DNS guard). iOS rejects them and Android
    // 1.1.7 rejects 10.0.0.0/8; the controller makes Xray direct rules there.
    final subnets = options.proxyOnly || _iOS || _android || options.bypassSubnets.isEmpty ? null : options.bypassSubnets;
    try {
      await _vless.startVless(
        remark: remark,
        config: prepared,
        proxyOnly: options.proxyOnly,
        blockedApps: options.proxyOnly || !_android || options.blockedApps.isEmpty ? null : options.blockedApps,
        bypassSubnets: subnets,
        // proxy = system DNS goes through the tunnel instead of the local network.
        androidDnsPolicy:
            _android && !options.proxyOnly && options.dnsThroughTunnel ? AndroidDnsPolicy.proxy : AndroidDnsPolicy.config,
        notificationDisconnectButtonName: disconnectLabel.length > 80 ? disconnectLabel.substring(0, 80) : disconnectLabel,
        // Windows: use the geo files next to the app instead of copying them
        // into a new private folder on every connect.
        geoAssetsDirectory: bundledGeoAssetsDirectory(),
      );
    } on PlatformException catch (e) {
      throw _map(e);
    }
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
  Future<void> stop() async {
    try {
      await _vless.stopVless();
    } on PlatformException catch (e) {
      throw _map(e);
    }
  }

  static const _native = MethodChannel('noisevpn/native');

  @override
  Future<bool?> isSessionAlive() async {
    if (!_android) return null;
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
  Future<int?> connectedDelay() async {
    try {
      final ms = await _vless.getConnectedServerDelay(url: AppConfig.pingUrl).timeout(const Duration(seconds: 15));
      return ms > 0 ? ms : null;
    } catch (e) {
      debugPrint('connected delay failed: $e');
      return null;
    }
  }

  @override
  Future<EngineCapabilities?> capabilities() async {
    try {
      await ensureInitialized();
      final c = await _vless.getCapabilities();
      // iOS lists Control Center only with the widget extension installed.
      final surfaces = _iOS && !c.controlCenterExtensionConfigured
          ? c.quickAccessSurfaces.where((s) => s != QuickAccessSurface.controlCenter && s != QuickAccessSurface.platformDefault)
          : c.quickAccessSurfaces;
      return EngineCapabilities(
        quickAccess: c.optionsVersion > 0 && surfaces.isNotEmpty,
        addQuickTile: c.requestAddQuickTile,
        customReconnect: c.customReconnectBackoff,
        onDemand: c.onDemand,
        alwaysOn: c.alwaysOn,
        alwaysOnEnabled: c.alwaysOnEnabled,
        lockdownEnabled: c.lockdownEnabled,
        killSwitch: c.killSwitch,
      );
    } catch (e) {
      debugPrint('capabilities unavailable: $e');
      return null;
    }
  }

  @override
  Future<QuickTileResult> addQuickTile() async {
    try {
      return switch (await _vless.requestAddQuickTile()) {
        QuickTileAddResult.added => QuickTileResult.added,
        QuickTileAddResult.alreadyAdded => QuickTileResult.alreadyAdded,
        QuickTileAddResult.declined => QuickTileResult.declined,
        QuickTileAddResult.unsupported => QuickTileResult.unsupported,
      };
    } catch (_) {
      return QuickTileResult.unsupported;
    }
  }

  @override
  Future<void> clearQuickAccess() => _vless.clearQuickAccessProfile();

  @override
  Future<String?> coreVersion() async {
    try {
      await ensureInitialized();
      final v = (await _vless.getCoreVersion()).trim();
      return v.isEmpty ? null : v;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> diagnostics() async {
    try {
      return await _vless.getProviderDebugSnapshot();
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() => _status.close();
}
