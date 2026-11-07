import 'dart:convert';

/// Configs for the fast Windows TUN engine: Xray keeps the server's own
/// config and serves it on a private, password-protected local SOCKS port;
/// sing-box owns the Wintun adapter, routes and DNS and sends everything to
/// that port (the way v2rayN does it). Pure Dart so it can be tested.
abstract final class WindowsTunConfig {
  /// The local SOCKS inbound Xray serves to sing-box.
  static const socksTag = 'noise-tun-in';

  /// DNS used by apps through the tunnel when the user picked none.
  static const defaultDns = '1.1.1.1';

  /// Turns a server's Xray config into one that only listens on
  /// 127.0.0.1:[port] with [user]/[pass]. Routing, DNS and outbounds stay as
  /// they are. Sniffing (route only) keeps domain rules such as "bypass
  /// Iranian sites" working.
  static String xray(String config, {required int port, required String user, required String pass}) {
    final json = jsonDecode(config) as Map<String, dynamic>;
    json['inbounds'] = [
      {
        'tag': socksTag,
        'listen': '127.0.0.1',
        'port': port,
        'protocol': 'socks',
        'settings': {
          'auth': 'password',
          'accounts': [
            {'user': user, 'pass': pass},
          ],
          'udp': true,
          'ip': '127.0.0.1',
        },
        'sniffing': {
          'enabled': true,
          'destOverride': ['http', 'tls', 'quic'],
          'routeOnly': true,
        },
      },
    ];
    // An API/stats block may point at inbounds that no longer exist.
    json.remove('api');
    json.remove('stats');
    json.remove('policy');
    final routing = json['routing'];
    if (routing is Map && routing['rules'] is List) {
      routing['rules'] = [
        for (final r in routing['rules'] as List)
          if (!(r is Map && (r['outboundTag'] == 'api' || r['inboundTag'] is List && (r['inboundTag'] as List).contains('api')))) r,
      ];
    }
    return jsonEncode(json);
  }

  static final _ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');

  /// Host names of the proxy servers in an Xray config. Their DNS lookups
  /// must not go through the tunnel, which needs them to come up first.
  static List<String> serverHosts(String config) {
    final hosts = <String>{};
    void addHost(Object? value) {
      if (value is! String) return;
      var host = value.trim();
      // "host:port" / "[v6]:port" (WireGuard endpoints).
      final bracket = RegExp(r'^\[(.+)\](:\d+)?$').firstMatch(host);
      if (bracket != null) return; // IPv6 literal
      final colon = host.lastIndexOf(':');
      if (colon > 0 && host.indexOf(':') == colon) host = host.substring(0, colon);
      if (host.isEmpty || _ipv4.hasMatch(host) || host.contains(':') || !host.contains('.')) return;
      hosts.add(host.toLowerCase());
    }

    void walk(Object? node) {
      if (node is Map) {
        for (final e in node.entries) {
          if (e.key == 'address' || e.key == 'endpoint' || e.key == 'server') {
            addHost(e.value);
          } else {
            walk(e.value);
          }
        }
      } else if (node is List) {
        node.forEach(walk);
      }
    }

    try {
      final json = jsonDecode(config);
      if (json is Map && json['outbounds'] is List) {
        for (final o in json['outbounds'] as List) {
          if (o is Map && o['protocol'] != 'freedom' && o['protocol'] != 'blackhole' && o['protocol'] != 'dns') {
            walk(o['settings']);
          }
        }
      }
    } catch (_) {}
    return hosts.toList()..sort();
  }

  /// DNS server for apps inside the tunnel, as sing-box `tcp` server fields
  /// (TCP works through every proxy type). Null server = default.
  static Map<String, Object> _dnsServer(String? choice) {
    var host = defaultDns;
    var port = 53;
    final c = choice?.trim() ?? '';
    final plain = c.startsWith('tcp://') ? c.substring(6) : (c.contains('://') ? '' : c);
    final m = RegExp(r'^(\d{1,3}(?:\.\d{1,3}){3})(?::(\d+))?$').firstMatch(plain);
    if (m != null) {
      host = m.group(1)!;
      port = int.tryParse(m.group(2) ?? '') ?? 53;
    }
    return {'type': 'tcp', 'tag': 'remote', 'server': host, 'server_port': port, 'detour': 'proxy'};
  }

  /// sing-box config: Wintun TUN in, Xray's local SOCKS out.
  static String singBox({
    required int socksPort,
    required String user,
    required String pass,
    required String xrayPath,
    required String singBoxPath,
    required int apiPort,
    required String apiSecret,
    required List<String> serverHosts,
    List<String> bypassSubnets = const [],
    String? dnsServer,
  }) {
    final config = {
      'log': {'level': 'warn', 'timestamp': true},
      'dns': {
        'servers': [
          _dnsServer(dnsServer),
          // The proxy servers' own names: the system resolver, outside the tunnel.
          {'type': 'local', 'tag': 'local'},
        ],
        'rules': [
          if (serverHosts.isNotEmpty) {'domain': serverHosts, 'server': 'local'},
        ],
        'final': 'remote',
        'strategy': 'prefer_ipv4',
      },
      'inbounds': [
        {
          'type': 'tun',
          'tag': 'tun-in',
          'interface_name': 'Noise VPN',
          'address': ['172.19.0.1/30', 'fdfe:dcba:9876::1/126'],
          'mtu': 9000,
          'auto_route': true,
          'strict_route': true,
          'stack': 'mixed',
          if (bypassSubnets.isNotEmpty) 'route_exclude_address': bypassSubnets,
        },
      ],
      'outbounds': [
        {
          'type': 'socks',
          'tag': 'proxy',
          'server': '127.0.0.1',
          'server_port': socksPort,
          'version': '5',
          'username': user,
          'password': pass,
        },
        {'type': 'direct', 'tag': 'direct'},
      ],
      'route': {
        'rules': [
          {'action': 'sniff'},
          {'protocol': 'dns', 'action': 'hijack-dns'},
          // Xray's own connections to the servers (and sing-box's) must not
          // loop back into the tunnel.
          {
            'process_path': [xrayPath, singBoxPath],
            'outbound': 'direct',
          },
          if (bypassSubnets.isNotEmpty) {'ip_cidr': bypassSubnets, 'outbound': 'direct'},
        ],
        'final': 'proxy',
        'auto_detect_interface': true,
        'default_domain_resolver': 'local',
      },
      'experimental': {
        'clash_api': {
          'external_controller': '127.0.0.1:$apiPort',
          'secret': apiSecret,
        },
      },
    };
    return const JsonEncoder.withIndent('  ').convert(config);
  }
}
