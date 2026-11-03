import 'package:flutter/foundation.dart';
import 'package:flutter_vless/flutter_vless.dart';

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

/// A subscription the user added.
@immutable
class SubscriptionSource {
  const SubscriptionSource({required this.id, required this.url, required this.name});

  final String id;
  final String url;

  /// What the user typed, or the link's host when they left it empty.
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'url': url, 'name': name};

  static SubscriptionSource? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], url = json['url'], name = json['name'];
    if (id is! String || url is! String) return null;
    return SubscriptionSource(id: id, url: url, name: name is String && name.isNotEmpty ? name : url);
  }
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

  bool get isLocal => url == null;

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
/// the whole list.
List<VpnServer> parseSubscription(String body, {required String sourceId}) {
  final List<FlutterVlessURL> parsed;
  try {
    parsed = FlutterVless.parseMany(body);
  } catch (_) {
    return const [];
  }

  final servers = <VpnServer>[];
  final seen = <String>{};
  for (final p in parsed) {
    try {
      final id = stableId('$sourceId|${p.url}');
      if (!seen.add(id)) continue;
      final remark = p.remark.trim();
      final info = RemarkInfo.parse(remark);
      final scheme = p.url.contains('://') ? p.url.split('://').first.toLowerCase() : 'xray';
      servers.add(VpnServer(
        id: id,
        sourceId: sourceId,
        shareLink: p.url,
        remark: remark.isEmpty ? p.address : remark,
        countryCode: info.countryCode,
        tag: info.tag,
        protocol: scheme,
        transport: p.network,
        host: p.address,
        port: p.port,
        config: p.getFullConfiguration(),
      ));
    } catch (_) {
      continue;
    }
  }
  return servers;
}
