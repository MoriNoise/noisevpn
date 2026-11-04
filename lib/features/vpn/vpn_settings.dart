import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs.dart';

/// Which apps use the tunnel (Android, VPN mode only).
enum PerAppMode {
  /// Every app.
  off,

  /// The selected apps skip the tunnel.
  bypass,

  /// Only the selected apps use the tunnel: every other launchable app is
  /// excluded. flutter_vless only takes an exclude list, so this is how
  /// "only these" is expressed.
  only,
}

/// The connection options flutter_vless 1.1.6 actually exposes:
/// `proxyOnly`, `blockedApps`, `bypassSubnets` and `androidDnsPolicy`.
@immutable
class VpnSettings {
  const VpnSettings({
    this.proxyOnly = false,
    this.socksPort = defaultSocksPort,
    this.perAppMode = PerAppMode.off,
    this.selectedApps = const {},
    this.bypassLan = true,
    this.dnsThroughTunnel = true,
  });

  /// The SOCKS port flutter_vless puts in every parsed config.
  static const defaultSocksPort = 8142;

  /// No VPN: only a local SOCKS5 proxy on 127.0.0.1:[socksPort].
  final bool proxyOnly;
  final int socksPort;
  final PerAppMode perAppMode;
  final Set<String> selectedApps;

  /// Keep private networks (router, printers, LAN) outside the tunnel.
  final bool bypassLan;

  /// Android: route system DNS through the proxy instead of the local network.
  final bool dnsThroughTunnel;

  /// RFC 1918, link-local and carrier-grade NAT ranges.
  static const lanSubnets = [
    '10.0.0.0/8',
    '172.16.0.0/12',
    '192.168.0.0/16',
    '169.254.0.0/16',
    '100.64.0.0/10',
  ];

  VpnSettings copyWith({
    bool? proxyOnly,
    int? socksPort,
    PerAppMode? perAppMode,
    Set<String>? selectedApps,
    bool? bypassLan,
    bool? dnsThroughTunnel,
  }) {
    return VpnSettings(
      proxyOnly: proxyOnly ?? this.proxyOnly,
      socksPort: socksPort ?? this.socksPort,
      perAppMode: perAppMode ?? this.perAppMode,
      selectedApps: selectedApps ?? this.selectedApps,
      bypassLan: bypassLan ?? this.bypassLan,
      dnsThroughTunnel: dnsThroughTunnel ?? this.dnsThroughTunnel,
    );
  }

  Map<String, dynamic> toJson() => {
        'proxyOnly': proxyOnly,
        'socksPort': socksPort,
        'perAppMode': perAppMode.name,
        'selectedApps': selectedApps.toList(),
        'bypassLan': bypassLan,
        'dnsThroughTunnel': dnsThroughTunnel,
      };

  static VpnSettings fromJson(Map<String, dynamic> j) {
    final port = j['socksPort'];
    return VpnSettings(
      proxyOnly: j['proxyOnly'] == true,
      socksPort: port is int && port >= 1024 && port <= 65535 ? port : defaultSocksPort,
      perAppMode: PerAppMode.values.firstWhere((m) => m.name == j['perAppMode'], orElse: () => PerAppMode.off),
      selectedApps: {
        for (final a in (j['selectedApps'] as List? ?? const []))
          if (a is String) a,
      },
      bypassLan: j['bypassLan'] != false,
      dnsThroughTunnel: j['dnsThroughTunnel'] != false,
    );
  }
}

class VpnSettingsController extends Notifier<VpnSettings> {
  static const _key = 'vpn.settings';

  @override
  VpnSettings build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const VpnSettings();
    try {
      return VpnSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const VpnSettings();
    }
  }

  void update(VpnSettings Function(VpnSettings) change) {
    state = change(state);
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(state.toJson()));
  }

  void toggleApp(String package) {
    update((s) {
      final apps = {...s.selectedApps};
      if (!apps.remove(package)) apps.add(package);
      return s.copyWith(selectedApps: apps);
    });
  }
}

final vpnSettingsProvider = NotifierProvider<VpnSettingsController, VpnSettings>(VpnSettingsController.new);
