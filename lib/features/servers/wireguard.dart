import 'dart:convert';

/// One WireGuard peer, from a `wireguard://` / `wg://` link or a `.conf`
/// file. flutter_vless only builds WireGuard from Clash or sing-box files, so
/// these two formats are parsed here into the same Xray `wireguard` outbound
/// the plugin generates.
class WireGuardProfile {
  WireGuardProfile({
    required this.privateKey,
    required this.publicKey,
    required this.host,
    required this.port,
    this.addresses = const [],
    this.presharedKey,
    this.mtu,
    this.keepAlive,
    this.reserved,
    this.allowedIPs = const [],
    String? remark,
  }) : remark = (remark == null || remark.trim().isEmpty) ? 'WireGuard $host' : remark.trim();

  final String privateKey;
  final String publicKey;
  final String host;
  final int port;
  final List<String> addresses;
  final String? presharedKey;
  final int? mtu;
  final int? keepAlive;

  /// Three bytes some providers (Cloudflare WARP) need.
  final List<int>? reserved;
  final List<String> allowedIPs;
  final String remark;

  static final _keyPattern = RegExp(r'^[A-Za-z0-9+/]{42,43}=?$');

  bool get _valid =>
      _keyPattern.hasMatch(privateKey) &&
      _keyPattern.hasMatch(publicKey) &&
      host.isNotEmpty &&
      port > 0 &&
      port < 65536 &&
      (presharedKey == null || _keyPattern.hasMatch(presharedKey!));

  String get _endpoint => host.contains(':') ? '[$host]:$port' : '$host:$port';

  /// Canonical link, stored as the server's share link and parsed again on
  /// the next launch.
  String toLink() {
    final q = <String, String>{
      'publickey': publicKey,
      if (addresses.isNotEmpty) 'address': addresses.join(','),
      if (presharedKey != null) 'presharedkey': presharedKey!,
      if (mtu != null) 'mtu': '$mtu',
      if (keepAlive != null) 'keepalive': '$keepAlive',
      if (reserved != null) 'reserved': reserved!.join(','),
      if (allowedIPs.isNotEmpty) 'allowedips': allowedIPs.join(','),
    };
    final query = q.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return 'wireguard://${Uri.encodeComponent(privateKey)}@$_endpoint?$query#${Uri.encodeComponent(remark)}';
  }

  /// Full Xray config, shaped like the configs flutter_vless generates.
  String toXrayConfig() {
    final config = {
      'log': {'loglevel': 'warning'},
      'inbounds': [
        {
          'tag': 'in_proxy',
          'listen': '127.0.0.1',
          'port': 10807,
          'protocol': 'socks',
          'settings': {'auth': 'noauth', 'udp': true, 'userLevel': 8},
          'sniffing': {
            'enabled': true,
            'destOverride': ['http', 'tls', 'quic'],
            'metadataOnly': false,
          },
        },
      ],
      'outbounds': [
        {
          'tag': 'proxy',
          'protocol': 'wireguard',
          'settings': {
            'secretKey': privateKey,
            if (addresses.isNotEmpty) 'address': addresses,
            'peers': [
              {
                'publicKey': publicKey,
                'endpoint': _endpoint,
                if (presharedKey != null) 'preSharedKey': presharedKey,
                if (keepAlive != null) 'keepAlive': keepAlive,
                'allowedIPs': allowedIPs.isEmpty ? const ['0.0.0.0/0', '::/0'] : allowedIPs,
              },
            ],
            if (mtu != null) 'mtu': mtu,
            // Xray reads `reserved` as bytes, which Go's JSON decodes from base64.
            if (reserved != null) 'reserved': base64Encode(reserved!),
          },
        },
        {
          'tag': 'direct',
          'protocol': 'freedom',
          'settings': {'domainStrategy': 'AsIs'},
        },
        {'tag': 'blackhole', 'protocol': 'blackhole', 'settings': <String, dynamic>{}},
      ],
      'routing': {'domainStrategy': 'AsIs', 'rules': <dynamic>[], 'balancers': <dynamic>[]},
    };
    return const JsonEncoder.withIndent('  ').convert(config);
  }

  static List<String> _list(String? value) => [
        for (final part in (value ?? '').split(','))
          if (part.trim().isNotEmpty) part.trim(),
      ];

  /// Adds /32 or /128 to bare interface addresses, as WireGuard means them.
  static List<String> _addresses(String? value) => [
        for (final a in _list(value)) a.contains('/') ? a : (a.contains(':') ? '$a/128' : '$a/32'),
      ];

  static List<int>? _reserved(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim();
    if (v.contains(',')) {
      final bytes = [for (final p in v.split(',')) int.tryParse(p.trim()) ?? -1];
      return bytes.length == 3 && bytes.every((b) => b >= 0 && b <= 255) ? bytes : null;
    }
    try {
      final bytes = base64Decode(v);
      return bytes.length == 3 ? bytes.toList() : null;
    } catch (_) {
      return null;
    }
  }

  /// `host:port` or `[ipv6]:port`.
  static (String, int)? _endpointOf(String? value) {
    if (value == null) return null;
    final v = value.trim();
    final m = RegExp(r'^\[([^\]]+)\]:(\d+)$').firstMatch(v) ?? RegExp(r'^([^:\s]+):(\d+)$').firstMatch(v);
    if (m == null) return null;
    final port = int.tryParse(m.group(2)!);
    return port == null ? null : (m.group(1)!, port);
  }

  /// `wireguard://<private key>@host:port?publickey=…&address=…#name`, also
  /// with `wg://` or the private key as a `privatekey` parameter.
  static WireGuardProfile? fromLink(String link) {
    final match = RegExp(r'^(?:wireguard|wg)://', caseSensitive: false).firstMatch(link.trim());
    if (match == null) return null;
    final Uri uri;
    try {
      uri = Uri.parse('wireguard://${link.trim().substring(match.end)}');
    } catch (_) {
      return null;
    }
    final q = {for (final e in uri.queryParameters.entries) e.key.toLowerCase().replaceAll('_', ''): e.value};
    final user = Uri.decodeComponent(uri.userInfo);
    final privateKey = user.isNotEmpty ? user : (q['privatekey'] ?? q['secretkey'] ?? '');
    var host = uri.host;
    if (host.startsWith('[') && host.endsWith(']')) host = host.substring(1, host.length - 1);
    final profile = WireGuardProfile(
      privateKey: privateKey,
      publicKey: q['publickey'] ?? q['peerpublickey'] ?? '',
      host: host,
      port: uri.hasPort ? uri.port : 51820,
      addresses: _addresses(q['address'] ?? q['ip'] ?? q['localaddress']),
      presharedKey: q['presharedkey'] ?? q['psk'],
      mtu: int.tryParse(q['mtu'] ?? ''),
      keepAlive: int.tryParse(q['keepalive'] ?? q['persistentkeepalive'] ?? ''),
      reserved: _reserved(q['reserved']),
      allowedIPs: _list(q['allowedips']),
      remark: uri.fragment.isEmpty ? null : Uri.decodeComponent(uri.fragment),
    );
    return profile._valid ? profile : null;
  }

  /// A `.conf` file: `[Interface]` + `[Peer]`. Only the first peer is used.
  static WireGuardProfile? fromConf(String text) {
    final iface = <String, String>{};
    final peer = <String, String>{};
    Map<String, String>? section;
    String? name;
    var peers = 0;
    for (final raw in const LineSplitter().convert(text)) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#') || line.startsWith(';')) {
        final m = RegExp(r'^[#;]\s*name\s*[=:]\s*(.+)$', caseSensitive: false).firstMatch(line);
        if (m != null) name ??= m.group(1)!.trim();
        continue;
      }
      final header = line.toLowerCase();
      if (header == '[interface]') {
        section = iface;
        continue;
      }
      if (header == '[peer]') {
        section = ++peers == 1 ? peer : null;
        continue;
      }
      final eq = line.indexOf('=');
      if (eq <= 0 || section == null) continue;
      final key = line.substring(0, eq).trim().toLowerCase();
      final value = line.substring(eq + 1).trim();
      // Repeated keys (several Address lines) are joined.
      section[key] = section.containsKey(key) ? '${section[key]},$value' : value;
    }
    final endpoint = _endpointOf(peer['endpoint']);
    if (endpoint == null) return null;
    final profile = WireGuardProfile(
      privateKey: iface['privatekey'] ?? '',
      publicKey: peer['publickey'] ?? '',
      host: endpoint.$1,
      port: endpoint.$2,
      addresses: _addresses(iface['address']),
      presharedKey: peer['presharedkey'],
      mtu: int.tryParse(iface['mtu'] ?? ''),
      keepAlive: int.tryParse(peer['persistentkeepalive'] ?? ''),
      reserved: _reserved(iface['reserved'] ?? peer['reserved']),
      allowedIPs: _list(peer['allowedips']),
      remark: name,
    );
    return profile._valid ? profile : null;
  }

  static final _linkLine = RegExp(r'^(?:wireguard|wg)://', caseSensitive: false);
  static final _confLine = RegExp(r'^(?:\[(?:interface|peer)\]|[#;].*|[A-Za-z][A-Za-z0-9]*\s*=.*)$', caseSensitive: false);

  /// Splits [text] into WireGuard profiles and everything else, which is
  /// handed to flutter_vless as before. A base64 subscription is decoded
  /// first when it contains WireGuard links.
  static (List<WireGuardProfile>, String) extract(String text) {
    var body = text;
    if (!body.contains('://') && !body.contains('[Interface]')) {
      final compact = body.replaceAll(RegExp(r'\s'), '');
      if (compact.length >= 16 && RegExp(r'^[A-Za-z0-9+/=_-]+$').hasMatch(compact)) {
        try {
          final decoded = utf8.decode(base64.decode(base64.normalize(compact.replaceAll('-', '+').replaceAll('_', '/'))));
          if (_linkLine.hasMatch(decoded.trimLeft()) || decoded.contains('\nwireguard://') || decoded.contains('\nwg://')) {
            body = decoded;
          }
        } catch (_) {}
      }
    }
    if (!body.toLowerCase().contains('wireguard://') &&
        !body.toLowerCase().contains('wg://') &&
        !body.toLowerCase().contains('[interface]')) {
      return (const [], text);
    }

    final profiles = <WireGuardProfile>[];
    final rest = <String>[];
    final lines = const LineSplitter().convert(body);
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (_linkLine.hasMatch(line)) {
        final p = fromLink(line);
        if (p != null) profiles.add(p);
        continue;
      }
      if (line.toLowerCase() == '[interface]') {
        final block = <String>[line];
        // Comments right above [Interface] (often "# Name = …") belong to it.
        while (rest.isNotEmpty && rest.last.trim().startsWith('#')) {
          block.insert(0, rest.removeLast());
        }
        var j = i + 1;
        for (; j < lines.length; j++) {
          final next = lines[j].trim();
          if (next.toLowerCase() == '[interface]' || _linkLine.hasMatch(next)) break;
          if (next.isEmpty || _confLine.hasMatch(next)) {
            block.add(next);
          } else {
            break;
          }
        }
        final p = fromConf(block.join('\n'));
        if (p != null) profiles.add(p);
        i = j - 1;
        continue;
      }
      rest.add(lines[i]);
    }
    return (profiles, rest.join('\n'));
  }
}
