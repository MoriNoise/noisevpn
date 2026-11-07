import 'package:flutter/foundation.dart';
import 'package:flutter_vless/flutter_vless.dart';

import 'countries.dart';
import 'wireguard.dart';

/// One connectable profile from the subscription.
@immutable
class VpnServer {
  const VpnServer({
    required this.id,
    required this.sourceId,
    required this.shareLink,
    required this.remark,
    required this.countryCode,
    required this.tag,
    required this.protocol,
    required this.transport,
    required this.host,
    required this.port,
    required this.config,
  });

  /// Stable across launches (hash of source + share link), used for pings.
  final String id;

  /// The subscription it came from, or [localSourceId].
  final String sourceId;

  /// The original link (or raw JSON) it was parsed from.
  final String shareLink;
  final String remark;

  /// ISO code from the flag emoji in the remark, null when there is none.
  final String? countryCode;

  /// Whatever follows the country in the remark, e.g. "AI Ready", "direct".
  final String? tag;
  final String protocol;
  final String transport;
  final String host;
  final int port;

  /// Full Xray JSON handed to flutter_vless.
  final String config;
}

/// Parsed `subscription-userinfo` header.
@immutable
class SubscriptionUsage {
  const SubscriptionUsage({
    required this.upload,
    required this.download,
    required this.total,
    required this.expire,
  });

  final int upload;
  final int download;

  /// 0 means no data cap.
  final int total;
  final DateTime? expire;

  int get used => upload + download;
  bool get unlimited => total <= 0;
  double get fraction => unlimited ? 0 : (used / total).clamp(0.0, 1.0);

  /// `upload=1; download=2; total=3; expire=1700000000`
  static SubscriptionUsage? parse(String? header) {
    if (header == null || header.trim().isEmpty) return null;
    final values = <String, int>{};
    for (final part in header.split(';')) {
      final kv = part.split('=');
      if (kv.length != 2) continue;
      final v = int.tryParse(kv[1].trim().split('.').first);
      if (v != null) values[kv[0].trim().toLowerCase()] = v;
    }
    if (values.isEmpty) return null;
    final expire = values['expire'] ?? 0;
    return SubscriptionUsage(
      upload: values['upload'] ?? 0,
      download: values['download'] ?? 0,
      total: values['total'] ?? 0,
      expire: expire > 0 ? DateTime.fromMillisecondsSinceEpoch(expire * 1000) : null,
    );
  }
}

/// How a subscription refreshes itself.
enum SubUpdateMode {
  /// Only when the user taps refresh.
  off,

  /// Every `profile-update-interval` hours, the header subscription panels
  /// (Marzban, 3x-ui, Hiddify…) send. [SubscriptionSource.updateHours] when
  /// the panel sends none.
  provider,

  /// Every [SubscriptionSource.updateHours] hours.
  interval,
}

/// A subscription the user added.
@immutable
class SubscriptionSource {
  const SubscriptionSource({
    required this.id,
    required this.url,
    required this.name,
    this.updateMode = SubUpdateMode.provider,
    this.updateHours = defaultUpdateHours,
  });

  static const defaultUpdateHours = 12;
  static const minUpdateHours = 1;
  static const maxUpdateHours = 168;

  final String id;
  final String url;

  /// What the user typed, or the link's host when they left it empty.
  final String name;
  final SubUpdateMode updateMode;
  final int updateHours;

  /// Time between automatic refreshes, or null when off. [providerHours] is
  /// the subscription's own `profile-update-interval`, if it sent one.
  Duration? interval(double? providerHours) {
    final hours = switch (updateMode) {
      SubUpdateMode.off => null,
      SubUpdateMode.provider =>
        providerHours != null && providerHours > 0 ? providerHours : updateHours.toDouble(),
      SubUpdateMode.interval => updateHours.toDouble(),
    };
    if (hours == null) return null;
    // Never more often than every 15 minutes, whatever a panel says.
    final minutes = (hours * 60).round().clamp(15, maxUpdateHours * 60);
    return Duration(minutes: minutes);
  }

  SubscriptionSource copyWith({String? url, String? name, SubUpdateMode? updateMode, int? updateHours}) {
    return SubscriptionSource(
      id: id,
      url: url ?? this.url,
      name: name ?? this.name,
      updateMode: updateMode ?? this.updateMode,
      updateHours: updateHours ?? this.updateHours,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'name': name,
        'updateMode': updateMode.name,
        'updateHours': updateHours,
      };

  static SubscriptionSource? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], url = json['url'], name = json['name'], hours = json['updateHours'];
    if (id is! String || url is! String) return null;
    return SubscriptionSource(
      id: id,
      url: url,
      name: name is String && name.isNotEmpty ? name : url,
      // Subscriptions saved before auto-update existed follow the panel.
      updateMode: SubUpdateMode.values.firstWhere((m) => m.name == json['updateMode'], orElse: () => SubUpdateMode.provider),
      updateHours: hours is int && hours >= minUpdateHours && hours <= maxUpdateHours ? hours : defaultUpdateHours,
    );
  }
}

/// `profile-update-interval: 12` (hours, sometimes fractional).
double? parseUpdateInterval(String? header) {
  if (header == null) return null;
  final v = double.tryParse(header.trim());
  return v != null && v > 0 && v.isFinite ? v : null;
}

/// One section of the server list: a subscription, or the local configs.
@immutable
class SourceData {
  const SourceData({
    required this.id,
    required this.name,
    required this.servers,
    this.url,
    this.usage,
    this.fetchedAt,
    this.refreshing = false,
    this.failed = false,
    this.subscription,
    this.providerHours,
  });

  final String id;
  final String name;

  /// null for local configs.
  final String? url;
  final List<VpnServer> servers;
  final SubscriptionUsage? usage;
  final DateTime? fetchedAt;
  final bool refreshing;

  /// The last refresh failed (servers, if any, are the saved copy).
  final bool failed;

  /// The saved subscription (null for local configs).
  final SubscriptionSource? subscription;

  /// The subscription's own `profile-update-interval`, in hours.
  final double? providerHours;

  bool get isLocal => url == null;

  /// Time between automatic refreshes, or null when there are none.
  Duration? get updateInterval => subscription?.interval(providerHours);

  SourceData copyWith({
    List<VpnServer>? servers,
    SubscriptionUsage? usage,
    DateTime? fetchedAt,
    bool? refreshing,
    bool? failed,
  }) {
    return SourceData(
      id: id,
      name: name,
      url: url,
      servers: servers ?? this.servers,
      usage: usage ?? this.usage,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      refreshing: refreshing ?? this.refreshing,
      failed: failed ?? this.failed,
      subscription: subscription,
      providerHours: providerHours,
    );
  }
}

@immutable
class ServersData {
  const ServersData(this.sources);

  final List<SourceData> sources;

  List<VpnServer> get servers => [for (final s in sources) ...s.servers];
  bool get isEmpty => sources.isEmpty;
  bool get refreshing => sources.any((s) => s.refreshing);

  /// Plan usage of the first subscription that reports it.
  SubscriptionUsage? get usage {
    for (final s in sources) {
      if (s.usage != null) return s.usage;
    }
    return null;
  }
}

/// Country + tag pulled out of a remark like `🇺🇸 US AI Ready`.
@immutable
class RemarkInfo {
  const RemarkInfo({required this.countryCode, required this.tag});

  final String? countryCode;
  final String? tag;

  static bool _isRegional(int r) => r >= 0x1F1E6 && r <= 0x1F1FF;

  static RemarkInfo parse(String raw) {
    final runes = raw.trim().runes.toList();
    String? code;
    final rest = StringBuffer();
    for (var i = 0; i < runes.length; i++) {
      final r = runes[i];
      if (r == 0xFE0F || r == 0x200D) continue;
      if (code == null && _isRegional(r) && i + 1 < runes.length && _isRegional(runes[i + 1])) {
        // The flag decides the country, so a typo in the text code
        // (SW for Sweden) doesn't matter.
        code = String.fromCharCodes([r - 0x1F1E6 + 0x41, runes[i + 1] - 0x1F1E6 + 0x41]);
        i++;
        continue;
      }
      rest.writeCharCode(r);
    }

    var words = rest
        .toString()
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !RegExp(r'^[|\-–—•·_]+$').hasMatch(w))
        .toList();
    if (words.isNotEmpty && RegExp(r'^[A-Z]{2,3}$').hasMatch(words.first)) {
      if (code == null && words.first.length == 2) code = words.first;
      words = words.sublist(1);
    }
    // No flag and no leading code: look for a country name or code anywhere.
    code ??= detectCountry(raw);
    return RemarkInfo(countryCode: code, tag: words.isEmpty ? null : words.join(' '));
  }
}

/// 32-bit FNV-1a, stable across runs (String.hashCode is not guaranteed to be).
String stableId(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

const localSourceId = 'local';

/// Turns a subscription body (or pasted configs) into servers. Entries
/// flutter_vless can't turn into a config are skipped instead of failing
/// the whole list. WireGuard links and `.conf` files are parsed here, since
/// flutter_vless only reads WireGuard from Clash / sing-box files.
List<VpnServer> parseSubscription(String body, {required String sourceId}) {
  final (wireGuard, rest) = WireGuardProfile.extract(body);

  List<FlutterVlessURL> parsed = const [];
  if (rest.trim().isNotEmpty) {
    try {
      parsed = FlutterVless.parseMany(rest);
    } catch (_) {
      parsed = const [];
    }
  }

  final servers = <VpnServer>[];
  final seen = <String>{};

  void add({
    required String link,
    required String remark,
    required String fallbackName,
    required String protocol,
    required String transport,
    required String host,
    required int port,
    required String config,
  }) {
    final id = stableId('$sourceId|$link');
    if (!seen.add(id)) return;
    final name = remark.trim();
    final info = RemarkInfo.parse(name);
    servers.add(VpnServer(
      id: id,
      sourceId: sourceId,
      shareLink: link,
      remark: name.isEmpty ? fallbackName : name,
      countryCode: info.countryCode,
      tag: info.tag,
      protocol: protocol,
      transport: transport,
      host: host,
      port: port,
      config: config,
    ));
  }

  for (final p in parsed) {
    try {
      add(
        link: p.url,
        remark: p.remark,
        fallbackName: p.address,
        protocol: p.url.contains('://') ? p.url.split('://').first.toLowerCase() : 'xray',
        transport: p.network,
        host: p.address,
        port: p.port,
        config: p.getFullConfiguration(),
      );
    } catch (_) {
      continue;
    }
  }
  for (final w in wireGuard) {
    add(
      link: w.toLink(),
      remark: w.remark,
      fallbackName: w.host,
      protocol: 'wireguard',
      transport: 'udp',
      host: w.host,
      port: w.port,
      config: w.toXrayConfig(),
    );
  }
  return servers;
}
