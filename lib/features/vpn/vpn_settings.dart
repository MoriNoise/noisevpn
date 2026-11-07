import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vless/flutter_vless.dart';

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

/// DNS server written into the Xray config. [auto] leaves the config's own
/// DNS alone (flutter_vless then sends DNS over TCP through the proxy).
enum DnsChoice { auto, cloudflare, google, quad9, adguard, custom }

/// Button on Android's VPN notification.
enum NotificationButton { disconnect, openApp, none }

/// Apple On Demand (OS restarts the tunnel when it drops).
enum OnDemandChoice { auto, on, off }

/// Every connection option the app exposes. Engine options
/// ([toVlessOptions]) go to flutter_vless 1.1.7 at initialization; the rest
/// are applied per session (start options and config tweaks).
@immutable
class VpnSettings {
  const VpnSettings({
    this.proxyOnly = false,
    this.socksPort = defaultSocksPort,
    this.perAppMode = PerAppMode.off,
    this.selectedApps = const {},
    this.bypassLan = true,
    this.dnsThroughTunnel = true,
    this.dns = DnsChoice.auto,
    this.customDns = '',
    this.bypassIran = false,
    this.blockAds = false,
    this.fragment = false,
    this.autoReconnect = true,
    this.reconnectAttempts = 0,
    this.reconnectMaxDelay = 60,
    this.onDemand = OnDemandChoice.auto,
    this.requireAlwaysOn = false,
    this.notificationButton = NotificationButton.disconnect,
    this.quickAccess = false,
    this.quickAccessUnlock = true,
    this.quickAccessOpensApp = false,
    this.diagnostics = true,
    this.windowsStrictTun = false,
  });

  /// Default local SOCKS port in proxy-only mode.
  static const defaultSocksPort = 8142;

  /// Choices offered for the reconnect limits (0 = unlimited).
  static const attemptChoices = [0, 3, 5, 10, 25];
  static const maxDelayChoices = [15, 30, 60, 120, 300];

  /// No VPN: only a local SOCKS5 proxy on 127.0.0.1:[socksPort].
  final bool proxyOnly;
  final int socksPort;
  final PerAppMode perAppMode;
  final Set<String> selectedApps;

  /// Keep private networks (router, printers, LAN) outside the tunnel.
  final bool bypassLan;

  /// Android: route system DNS through the proxy instead of the local network.
  final bool dnsThroughTunnel;

  final DnsChoice dns;

  /// Used when [dns] is [DnsChoice.custom]: an IP, `host`, or a DNS URL
  /// (`tcp://`, `https://`, `quic+local://`…).
  final String customDns;

  /// Iranian sites and IPs connect directly instead of through the server.
  final bool bypassIran;

  /// Ads and trackers are dropped (needs the GeoSite file, so Android and
  /// Windows only).
  final bool blockAds;

  /// Splits the TLS ClientHello into small pieces, which gets past some SNI
  /// filtering. TLS servers only.
  final bool fragment;

  final bool autoReconnect;

  /// 0 means unlimited.
  final int reconnectAttempts;

  /// Longest wait between reconnect attempts, in seconds.
  final int reconnectMaxDelay;
  final OnDemandChoice onDemand;

  /// Android: refuse to connect unless the system "Always-on VPN" is set.
  final bool requireAlwaysOn;
  final NotificationButton notificationButton;

  /// Quick Settings tile (Android), menu bar (macOS) or tray icon (Windows).
  final bool quickAccess;
  final bool quickAccessUnlock;

  /// The quick control opens the app instead of toggling the VPN.
  final bool quickAccessOpensApp;

  /// Keep a privacy-filtered native log for troubleshooting.
  final bool diagnostics;

  /// Windows VPN mode through flutter_vless's protected tunnel (kill switch,
  /// about 10 s to connect) instead of the fast sing-box engine.
  final bool windowsStrictTun;

  /// RFC 1918, link-local and carrier-grade NAT ranges.
  static const lanSubnets = [
    '10.0.0.0/8',
    '172.16.0.0/12',
    '192.168.0.0/16',
    '169.254.0.0/16',
    '100.64.0.0/10',
  ];

  /// The DNS server for the Xray config, or null to keep the config's own.
  String? get dnsServer {
    return switch (dns) {
      DnsChoice.auto => null,
      DnsChoice.cloudflare => 'tcp://1.1.1.1',
      DnsChoice.google => 'tcp://8.8.8.8',
      DnsChoice.quad9 => 'tcp://9.9.9.9',
      DnsChoice.adguard => 'tcp://94.140.14.14',
      DnsChoice.custom => normalizeDns(customDns),
    };
  }

  /// A bare IP or host goes over TCP, which works through every proxy type.
  /// Anything with a scheme is used as written. Null when it isn't usable.
  static String? normalizeDns(String raw) {
    final v = raw.trim();
    if (v.isEmpty || v.contains(RegExp(r'\s'))) return null;
    if (v.contains('://')) return v;
    if (!RegExp(r'^[A-Za-z0-9.:\-\[\]]+$').hasMatch(v)) return null;
    return 'tcp://$v';
  }

  /// Engine options for flutter_vless. [quickLabel] names the tile/menu item.
  VlessOptions toVlessOptions({required String disconnectLabel, required String quickLabel}) {
    String clip(String s) => s.length > 80 ? s.substring(0, 80) : s;
    final delay = reconnectMaxDelay.clamp(1, 600);
    return VlessOptions(
      notification: NotificationOptions(
        buttonLabel: clip(disconnectLabel),
        action: switch (notificationButton) {
          NotificationButton.disconnect => VlessNotificationAction.disconnect,
          NotificationButton.openApp => VlessNotificationAction.openApp,
          NotificationButton.none => VlessNotificationAction.none,
        },
      ),
      quickAccess: QuickAccessOptions(
        enabled: quickAccess,
        label: clip(quickLabel),
        action: quickAccessOpensApp ? VlessSystemAction.openApp : VlessSystemAction.toggle,
        requireUnlock: quickAccessUnlock,
        appleSymbol: 'shield.lefthalf.filled',
      ),
      reconnect: ReconnectOptions(
        enabled: autoReconnect,
        maxDelay: Duration(seconds: delay),
        maxAttempts: reconnectAttempts.clamp(0, 1000),
      ),
      protection: ProtectionOptions(
        onDemand: switch (onDemand) {
          // On Demand needs auto-reconnect; fall back rather than fail.
          OnDemandChoice.on => autoReconnect ? OnDemandMode.enabled : OnDemandMode.disabled,
          OnDemandChoice.off => OnDemandMode.disabled,
          OnDemandChoice.auto => OnDemandMode.platformDefault,
        },
        alwaysOn: requireAlwaysOn ? AlwaysOnMode.requireEnabled : AlwaysOnMode.system,
      ),
      diagnostics: DiagnosticsOptions(enabled: diagnostics),
    );
  }

  VpnSettings copyWith({
    bool? proxyOnly,
    int? socksPort,
    PerAppMode? perAppMode,
    Set<String>? selectedApps,
    bool? bypassLan,
    bool? dnsThroughTunnel,
    DnsChoice? dns,
    String? customDns,
    bool? bypassIran,
    bool? blockAds,
    bool? fragment,
    bool? autoReconnect,
    int? reconnectAttempts,
    int? reconnectMaxDelay,
    OnDemandChoice? onDemand,
    bool? requireAlwaysOn,
    NotificationButton? notificationButton,
    bool? quickAccess,
    bool? quickAccessUnlock,
    bool? quickAccessOpensApp,
    bool? diagnostics,
    bool? windowsStrictTun,
  }) {
    return VpnSettings(
      proxyOnly: proxyOnly ?? this.proxyOnly,
      socksPort: socksPort ?? this.socksPort,
      perAppMode: perAppMode ?? this.perAppMode,
      selectedApps: selectedApps ?? this.selectedApps,
      bypassLan: bypassLan ?? this.bypassLan,
      dnsThroughTunnel: dnsThroughTunnel ?? this.dnsThroughTunnel,
      dns: dns ?? this.dns,
      customDns: customDns ?? this.customDns,
      bypassIran: bypassIran ?? this.bypassIran,
      blockAds: blockAds ?? this.blockAds,
      fragment: fragment ?? this.fragment,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      reconnectMaxDelay: reconnectMaxDelay ?? this.reconnectMaxDelay,
      onDemand: onDemand ?? this.onDemand,
      requireAlwaysOn: requireAlwaysOn ?? this.requireAlwaysOn,
      notificationButton: notificationButton ?? this.notificationButton,
      quickAccess: quickAccess ?? this.quickAccess,
      quickAccessUnlock: quickAccessUnlock ?? this.quickAccessUnlock,
      quickAccessOpensApp: quickAccessOpensApp ?? this.quickAccessOpensApp,
      diagnostics: diagnostics ?? this.diagnostics,
      windowsStrictTun: windowsStrictTun ?? this.windowsStrictTun,
    );
  }

  Map<String, dynamic> toJson() => {
        'proxyOnly': proxyOnly,
        'socksPort': socksPort,
        'perAppMode': perAppMode.name,
        'selectedApps': selectedApps.toList(),
        'bypassLan': bypassLan,
        'dnsThroughTunnel': dnsThroughTunnel,
        'dns': dns.name,
        'customDns': customDns,
        'bypassIran': bypassIran,
        'blockAds': blockAds,
        'fragment': fragment,
        'autoReconnect': autoReconnect,
        'reconnectAttempts': reconnectAttempts,
        'reconnectMaxDelay': reconnectMaxDelay,
        'onDemand': onDemand.name,
        'requireAlwaysOn': requireAlwaysOn,
        'notificationButton': notificationButton.name,
        'quickAccess': quickAccess,
        'quickAccessUnlock': quickAccessUnlock,
        'quickAccessOpensApp': quickAccessOpensApp,
        'diagnostics': diagnostics,
        'windowsStrictTun': windowsStrictTun,
      };

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.firstWhere((v) => v.name == name, orElse: () => fallback);

  static VpnSettings fromJson(Map<String, dynamic> j) {
    final port = j['socksPort'];
    final attempts = j['reconnectAttempts'];
    final maxDelay = j['reconnectMaxDelay'];
    return VpnSettings(
      proxyOnly: j['proxyOnly'] == true,
      socksPort: port is int && port >= 1024 && port <= 65535 ? port : defaultSocksPort,
      perAppMode: _enum(PerAppMode.values, j['perAppMode'], PerAppMode.off),
      selectedApps: {
        for (final a in (j['selectedApps'] as List? ?? const []))
          if (a is String) a,
      },
      bypassLan: j['bypassLan'] != false,
      dnsThroughTunnel: j['dnsThroughTunnel'] != false,
      dns: _enum(DnsChoice.values, j['dns'], DnsChoice.auto),
      customDns: j['customDns'] is String ? j['customDns'] as String : '',
      bypassIran: j['bypassIran'] == true,
      blockAds: j['blockAds'] == true,
      fragment: j['fragment'] == true,
      autoReconnect: j['autoReconnect'] != false,
      reconnectAttempts: attempts is int && attemptChoices.contains(attempts) ? attempts : 0,
      reconnectMaxDelay: maxDelay is int && maxDelayChoices.contains(maxDelay) ? maxDelay : 60,
      onDemand: _enum(OnDemandChoice.values, j['onDemand'], OnDemandChoice.auto),
      requireAlwaysOn: j['requireAlwaysOn'] == true,
      notificationButton: _enum(NotificationButton.values, j['notificationButton'], NotificationButton.disconnect),
      quickAccess: j['quickAccess'] == true,
      quickAccessUnlock: j['quickAccessUnlock'] != false,
      quickAccessOpensApp: j['quickAccessOpensApp'] == true,
      diagnostics: j['diagnostics'] != false,
      windowsStrictTun: j['windowsStrictTun'] == true,
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
