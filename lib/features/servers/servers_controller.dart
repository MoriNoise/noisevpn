import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_info.dart';
import '../../core/prefs.dart';
import '../vpn/batch_ping.dart';
import '../vpn/vpn_backend.dart';
import '../vpn/vpn_controller.dart';
import 'server_models.dart';

// ── Sources: subscriptions + local configs ──────────────────────────────

class SubscriptionException implements Exception {
  const SubscriptionException(this.message);
  final String message;
  @override
  String toString() => 'SubscriptionException: $message';
}

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

enum AddSubscriptionResult { added, invalidUrl, duplicate }

/// Every server the app knows: subscriptions the user added (each with a
/// saved copy so the list shows instantly and survives a failed refresh)
/// and configs pasted by hand.
class ServersController extends Notifier<ServersData> {
  static const _subsKey = 'sources.subscriptions';
  static const _localKey = 'sources.local';
  static String _bodyKey(String id) => 'sources.$id.body';
  static String _infoKey(String id) => 'sources.$id.userinfo';
  static String _timeKey(String id) => 'sources.$id.time';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  ServersData build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final subs = _readSubs(prefs);
    final local = prefs.getStringList(_localKey) ?? const <String>[];

    final sources = <SourceData>[
      for (final sub in subs) _fromCache(prefs, sub).copyWith(refreshing: true),
      if (local.isNotEmpty) _localSource(local),
    ];
    // Refresh behind the saved copies; can't touch state during build.
    Future.microtask(() async {
      _autoPing();
      await Future.wait([for (final sub in subs) refreshOne(sub.id)]);
    });
    return ServersData(sources);
  }

  List<SubscriptionSource> _readSubs(SharedPreferences prefs) {
    final raw = prefs.getString(_subsKey);
    if (raw == null) return const [];
    try {
      return [
        for (final e in jsonDecode(raw) as List)
          if (SubscriptionSource.fromJson(e) case final sub?) sub,
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeSubs(List<SubscriptionSource> subs) =>
      _prefs.setString(_subsKey, jsonEncode([for (final s in subs) s.toJson()]));

  SourceData _fromCache(SharedPreferences prefs, SubscriptionSource sub) {
    final body = prefs.getString(_bodyKey(sub.id));
    final time = prefs.getInt(_timeKey(sub.id));
    return SourceData(
      id: sub.id,
      name: sub.name,
      url: sub.url,
      servers: body == null ? const [] : parseSubscription(body, sourceId: sub.id),
      usage: SubscriptionUsage.parse(prefs.getString(_infoKey(sub.id))),
      fetchedAt: time == null ? null : DateTime.fromMillisecondsSinceEpoch(time),
    );
  }

  SourceData _localSource(List<String> links) => SourceData(
        id: localSourceId,
        name: localSourceId,
        servers: parseSubscription(links.join('\n'), sourceId: localSourceId),
      );

  void _replace(String id, SourceData Function(SourceData) update) {
    state = ServersData([for (final s in state.sources) s.id == id ? update(s) : s]);
  }

  void _autoPing() {
    Future.microtask(() {
      if (ref.read(vpnControllerProvider).phase != VpnPhase.disconnected) return;
      ref.read(pingControllerProvider.notifier).testAll(state.servers, onlyMissing: true);
    });
  }

  /// Downloads one subscription. On failure the saved servers stay.
  Future<void> refreshOne(String id) async {
    SourceData? source;
    for (final s in state.sources) {
      if (s.id == id) source = s;
    }
    final url = source?.url;
    if (source == null || url == null) return;
    _replace(id, (s) => s.copyWith(refreshing: true));

    try {
      final response = await ref.read(httpClientProvider).get(
        Uri.parse(url),
        headers: {'User-Agent': 'NoiseVPN/${AppInfo.version}', 'Accept': '*/*'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw SubscriptionException('HTTP ${response.statusCode}');

      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      final servers = parseSubscription(body, sourceId: id);
      if (servers.isEmpty) throw const SubscriptionException('no supported servers');

      final info = response.headers['subscription-userinfo'];
      final now = DateTime.now();
      await _prefs.setString(_bodyKey(id), body);
      await _prefs.setInt(_timeKey(id), now.millisecondsSinceEpoch);
      if (info == null) {
        await _prefs.remove(_infoKey(id));
      } else {
        await _prefs.setString(_infoKey(id), info);
      }
      if (!state.sources.any((s) => s.id == id)) return; // removed meanwhile
      _replace(
        id,
        (s) => SourceData(
          id: s.id,
          name: s.name,
          url: s.url,
          servers: servers,
          usage: SubscriptionUsage.parse(info),
          fetchedAt: now,
        ),
      );
      _autoPing();
    } catch (e) {
      debugPrint('subscription $id refresh failed: $e');
      if (!state.sources.any((s) => s.id == id)) return;
      _replace(id, (s) => s.copyWith(refreshing: false, failed: true));
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      for (final s in state.sources)
        if (!s.isLocal) refreshOne(s.id),
    ]);
  }

  Future<AddSubscriptionResult> addSubscription(String rawUrl, {String name = ''}) async {
    final url = rawUrl.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
      return AddSubscriptionResult.invalidUrl;
    }
    final subs = _readSubs(_prefs);
    if (subs.any((s) => s.url == url)) return AddSubscriptionResult.duplicate;

    final sub = SubscriptionSource(
      id: stableId('$url|${DateTime.now().microsecondsSinceEpoch}'),
      url: url,
      name: name.trim().isEmpty ? uri.host : name.trim(),
    );
    await _writeSubs([...subs, sub]);

    // Subscriptions sit above the local configs.
    final local = state.sources.where((s) => s.isLocal).toList();
    final others = state.sources.where((s) => !s.isLocal).toList();
    state = ServersData([
      ...others,
      SourceData(id: sub.id, name: sub.name, url: sub.url, servers: const [], refreshing: true),
      ...local,
    ]);
    unawaited(refreshOne(sub.id));
    return AddSubscriptionResult.added;
  }

  /// Adds every config found in [text] (share links, one per line, raw
  /// JSON or a base64 blob). Returns how many new ones were added.
  Future<int> addLocal(String text) async {
    final parsed = parseSubscription(text, sourceId: localSourceId);
    final existing = _prefs.getStringList(_localKey) ?? const <String>[];
    final links = [...existing];
    var added = 0;
    for (final server in parsed) {
      if (!links.contains(server.shareLink)) {
        links.add(server.shareLink);
        added++;
      }
    }
    if (added == 0) return 0;
    await _prefs.setStringList(_localKey, links);
    state = ServersData([
      ...state.sources.where((s) => !s.isLocal),
      _localSource(links),
    ]);
    _autoPing();
    return added;
  }

  /// Removes a subscription, or all local configs for [localSourceId].
  Future<void> removeSource(String id) async {
    if (id == localSourceId) {
      await _prefs.remove(_localKey);
    } else {
      await _writeSubs(_readSubs(_prefs).where((s) => s.id != id).toList());
      for (final k in [_bodyKey(id), _infoKey(id), _timeKey(id)]) {
        await _prefs.remove(k);
      }
    }
    state = ServersData(state.sources.where((s) => s.id != id).toList());
  }

  Future<void> removeLocalServer(VpnServer server) async {
    final links = [...(_prefs.getStringList(_localKey) ?? const <String>[])]..remove(server.shareLink);
    if (links.isEmpty) {
      await removeSource(localSourceId);
      return;
    }
    await _prefs.setStringList(_localKey, links);
    state = ServersData([
      ...state.sources.where((s) => !s.isLocal),
      _localSource(links),
    ]);
  }
}

final serversControllerProvider = NotifierProvider<ServersController, ServersData>(ServersController.new);

// ── Ping ──────────────────────────────────────────────────────────────────

@immutable
class PingResult {
  const PingResult({required this.ms, required this.testing});

  /// null = failed (or not tested yet while [testing]).
  final int? ms;
  final bool testing;
}

final batchPingerProvider = Provider<BatchPinger>((ref) => createBatchPinger());

/// Whether parallel ping can run on this device (an Xray binary was found).
final batchPingAvailableProvider = FutureProvider<bool>((ref) => ref.watch(batchPingerProvider).isAvailable());

/// Whether any ping engine is available: parallel, or the plugin's own.
final canPingProvider = Provider<bool>((ref) {
  final batch = ref.watch(batchPingAvailableProvider).valueOrNull ?? false;
  return batch || ref.watch(vpnBackendProvider).isSupported;
});

/// Real delay for every server: an HTTP request through that server's own
/// config, 5 s timeout each.
///
/// All servers are tested at once through one Xray process, the way
/// v2rayNG and Happ do it. flutter_vless's own probe is the fallback: it
/// starts a fresh Xray (and copies the geo files) per server and runs one at
/// a time, which is why it was slow.
class PingController extends Notifier<Map<String, PingResult>> {
  static const timeout = Duration(seconds: 5);
  static const _drain = Duration(seconds: 12);

  bool _running = false;

  @override
  Map<String, PingResult> build() => const {};

  bool get isRunning => _running;

  void _set(String id, int? ms, {required bool testing}) {
    state = {...state, id: PingResult(ms: ms, testing: testing)};
  }

  Future<int?> _pluginProbe(VpnBackend backend, VpnServer server) async {
    final probe = backend.delay(server);
    final ms = await Future.any<int?>([probe, Future<int?>.delayed(timeout, () => null)]);
    // The native probe can't be cancelled and runs one at a time; let it
    // finish so the next server's 5 s starts on an idle engine.
    if (ms == null) await probe.timeout(_drain, onTimeout: () => null);
    return ms;
  }

  Future<void> testAll(List<VpnServer> servers, {bool onlyMissing = false}) async {
    if (_running) return;
    final targets = onlyMissing ? servers.where((s) => !state.containsKey(s.id)).toList() : [...servers];
    if (targets.isEmpty) return;
    final backend = ref.read(vpnBackendProvider);
    final batch = ref.read(batchPingerProvider);
    final batchReady = await batch.isAvailable();
    if (!batchReady && !backend.isSupported) return;
    _running = true;

    state = {
      ...state,
      for (final s in targets) s.id: PingResult(ms: state[s.id]?.ms, testing: true),
    };

    try {
      if (batchReady) {
        var answered = 0;
        final results = <String, int?>{};
        final ran = await batch.run(targets, timeout: timeout, onResult: (id, ms) {
          results[id] = ms;
          if (ms != null) answered++;
          _set(id, ms, testing: false);
        });
        if (ran && answered > 0) return;
        if (ran && !backend.isSupported) return;
        // Nothing answered: make sure the batch engine itself isn't the
        // problem before reporting every server as down.
        if (ran && targets.length > 1) {
          final check = await _pluginProbe(backend, targets.first);
          if (check == null) {
            _set(targets.first.id, null, testing: false);
            return;
          }
        }
        for (final s in targets) {
          _set(s.id, state[s.id]?.ms, testing: true);
        }
      }

      if (!backend.isSupported) return;
      for (final server in targets) {
        _set(server.id, state[server.id]?.ms, testing: true);
        _set(server.id, await _pluginProbe(backend, server), testing: false);
      }
    } finally {
      _running = false;
      // Never leave a spinner behind.
      if (state.values.any((p) => p.testing)) {
        state = {for (final e in state.entries) e.key: PingResult(ms: e.value.ms, testing: false)};
      }
    }
  }
}

final pingControllerProvider =
    NotifierProvider<PingController, Map<String, PingResult>>(PingController.new);

// ── Selection ─────────────────────────────────────────────────────────────

/// What the user picked: [auto] (fastest server) or one server.
class SelectionController extends Notifier<String> {
  static const auto = 'auto';
  static const _key = 'servers.selection';

  static String keyFor(VpnServer server) => 'server:${server.id}';

  @override
  String build() => ref.watch(sharedPreferencesProvider).getString(_key) ?? auto;

  void select(String key) {
    state = key;
    ref.read(sharedPreferencesProvider).setString(_key, key);
  }
}

final selectionProvider = NotifierProvider<SelectionController, String>(SelectionController.new);

/// Fastest server in [servers] by measured ping; untested ones count as slow,
/// failed ones are used only when nothing else answered.
VpnServer? fastestOf(List<VpnServer> servers, Map<String, PingResult> pings) {
  if (servers.isEmpty) return null;
  VpnServer? best;
  var bestMs = 1 << 30;
  for (final s in servers) {
    final ms = pings[s.id]?.ms;
    if (ms != null && ms < bestMs) {
      best = s;
      bestMs = ms;
    }
  }
  return best ?? servers.first;
}

/// The server a tap on Connect would use right now.
final resolvedServerProvider = Provider<VpnServer?>((ref) {
  final servers = ref.watch(serversControllerProvider).servers;
  if (servers.isEmpty) return null;
  final selection = ref.watch(selectionProvider);
  final pings = ref.watch(pingControllerProvider);

  if (selection != SelectionController.auto) {
    for (final s in servers) {
      if (SelectionController.keyFor(s) == selection) return s;
    }
    // The picked server left the subscription: fall back to the fastest.
  }
  return fastestOf(servers, pings);
});
