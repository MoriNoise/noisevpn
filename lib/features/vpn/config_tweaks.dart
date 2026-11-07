import 'dart:convert';

/// Edits made to a server's Xray JSON before it is started. Everything here
/// is plain Xray config: no simulated behaviour, and nothing is added when
/// every option is off.
class ConfigTweaks {
  const ConfigTweaks({
    this.dnsServer,
    this.directSubnets = const [],
    this.bypassIran = false,
    this.blockAds = false,
    this.fragment = false,
    this.geoData = true,
  });

  /// Replaces the config's DNS servers when set.
  final String? dnsServer;

  /// IP ranges routed to the direct outbound inside Xray. Used for "Bypass
  /// LAN" on iOS, where flutter_vless rejects system `bypassSubnets`.
  final List<String> directSubnets;
  final bool bypassIran;
  final bool blockAds;
  final bool fragment;

  /// Whether geoip.dat / geosite.dat exist on this platform. flutter_vless
  /// ships them on Android and Windows; the Apple runtimes have none, and a
  /// rule that names a missing dataset stops Xray from starting.
  final bool geoData;

  bool get isEmpty =>
      dnsServer == null && directSubnets.isEmpty && !bypassIran && !blockAds && !fragment;

  /// Fragment settings (Hiddify / v2rayNG defaults).
  static const fragmentSettings = {
    'packets': 'tlshello',
    'length': '100-200',
    'interval': '10-20',
  };

  /// Returns [config] with the tweaks applied, or unchanged when it isn't a
  /// JSON object (the engine then reports the real error).
  String apply(String config) {
    if (isEmpty) return config;
    final Object? decoded;
    try {
      decoded = jsonDecode(config);
    } catch (_) {
      return config;
    }
    if (decoded is! Map<String, dynamic>) return config;
    final json = decoded;
    final outbounds = json['outbounds'];
    if (outbounds is! List || outbounds.isEmpty) return config;

    final rules = <Map<String, dynamic>>[];
    String? directTag;
    String direct() => directTag ??= _ensureOutbound(outbounds, 'freedom', 'direct');

    if (directSubnets.isNotEmpty) {
      rules.add({'type': 'field', 'ip': [...directSubnets], 'outboundTag': direct()});
    }
    if (blockAds && geoData) {
      final block = _ensureOutbound(outbounds, 'blackhole', 'block');
      rules.add({'type': 'field', 'domain': ['geosite:category-ads-all'], 'outboundTag': block});
    }
    if (bypassIran) {
      rules.add({
        'type': 'field',
        'domain': [if (geoData) 'geosite:category-ir', r'regexp:\.ir$'],
        'outboundTag': direct(),
      });
      if (geoData) rules.add({'type': 'field', 'ip': ['geoip:ir'], 'outboundTag': direct()});
    }

    if (rules.isNotEmpty) {
      final Map<String, dynamic> routing =
          json['routing'] is Map<String, dynamic> ? json['routing'] as Map<String, dynamic> : <String, dynamic>{};
      json['routing'] = routing;
      final existing = routing['rules'] is List ? routing['rules'] as List : const [];
      // Ours first, so they win over the server's catch-all rules.
      routing['rules'] = [...rules, ...existing];
    }

    final dns = dnsServer;
    if (dns != null) {
      final current = json['dns'] is Map<String, dynamic> ? json['dns'] as Map<String, dynamic> : <String, dynamic>{};
      json['dns'] = {...current, 'servers': [dns]};
    }

    if (fragment) _addFragment(outbounds);

    return const JsonEncoder.withIndent('  ').convert(json);
  }

  /// Tag of the first outbound with [protocol], adding one when missing.
  static String _ensureOutbound(List outbounds, String protocol, String preferredTag) {
    for (final o in outbounds) {
      if (o is Map && o['protocol'] == protocol && o['tag'] is String && (o['tag'] as String).isNotEmpty) {
        return o['tag'] as String;
      }
    }
    final tags = {for (final o in outbounds) if (o is Map) o['tag']};
    var tag = preferredTag;
    for (var i = 2; tags.contains(tag); i++) {
      tag = '$preferredTag$i';
    }
    outbounds.add({'tag': tag, 'protocol': protocol, 'settings': <String, dynamic>{}});
    return tag;
  }

  static const _fragmentProtocols = {'vless', 'vmess', 'trojan', 'shadowsocks'};
  static const _tcpNetworks = {'tcp', 'raw', 'ws', 'grpc', 'httpupgrade', 'http', 'h2', 'xhttp', 'splithttp'};

  /// Routes the TLS proxy outbounds' own connections through a freedom
  /// outbound that fragments the ClientHello. Reality, QUIC/KCP, HTTP/3 and
  /// outbounds that already chain through another outbound are left alone.
  static void _addFragment(List outbounds) {
    final targets = <Map>[];
    for (final o in outbounds) {
      if (o is! Map || !_fragmentProtocols.contains(o['protocol'])) continue;
      final stream = o['streamSettings'];
      if (stream is! Map || stream['security'] != 'tls') continue;
      final network = (stream['network'] ?? 'tcp').toString().toLowerCase();
      if (!_tcpNetworks.contains(network)) continue;
      final tls = stream['tlsSettings'];
      final alpn = tls is Map && tls['alpn'] is List ? tls['alpn'] as List : const [];
      if (alpn.contains('h3')) continue;
      final sockopt = stream['sockopt'];
      if (sockopt is Map && sockopt['dialerProxy'] != null) continue;
      if (o['proxySettings'] != null) continue;
      targets.add(o);
    }
    if (targets.isEmpty) return;

    final tags = {for (final o in outbounds) if (o is Map) o['tag']};
    var tag = 'fragment';
    for (var i = 2; tags.contains(tag); i++) {
      tag = 'fragment$i';
    }
    outbounds.add({
      'tag': tag,
      'protocol': 'freedom',
      'settings': {'fragment': fragmentSettings},
    });
    for (final o in targets) {
      final stream = o['streamSettings'] as Map;
      final sockopt = stream['sockopt'] is Map ? stream['sockopt'] as Map : (stream['sockopt'] = <String, dynamic>{}) as Map;
      sockopt['dialerProxy'] = tag;
    }
  }
}
