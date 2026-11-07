import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'vpn_backend.dart';
import 'windows_tun.dart';
import 'windows_tun_config.dart';

WindowsTunEngine? createWindowsTunEngine() {
  if (!Platform.isWindows) return null;
  final dir = '${File(Platform.resolvedExecutable).parent.path}\\xray';
  final xray = File('$dir\\xray.exe');
  final box = File('$dir\\sing-box.exe');
  if (!xray.existsSync() || !box.existsSync()) return null;
  return _SingBoxTun(dir: dir, xrayPath: xray.absolute.path, boxPath: box.absolute.path);
}

class _SingBoxTun implements WindowsTunEngine {
  _SingBoxTun({required this.dir, required this.xrayPath, required this.boxPath});

  final String dir;
  final String xrayPath;
  final String boxPath;

  final _status = StreamController<VpnStatusEvent>.broadcast();
  Process? _xray;
  Process? _box;
  bool _stopping = false;
  DateTime? _since;
  HttpClient? _api;
  StreamSubscription<String>? _traffic;
  Timer? _tick;
  int _up = 0, _down = 0, _upSpeed = 0, _downSpeed = 0;

  /// The adapter address in [WindowsTunConfig.singBox].
  static const _tunAddress = '172.19.0.1';

  @override
  Stream<VpnStatusEvent> get status => _status.stream;

  @override
  bool get isActive => _box != null && _xray != null && !_stopping;

  String get _work {
    final base = Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path;
    return '$base\\NoiseVPN\\tun';
  }

  File get _pidFile => File('$_work\\pids');

  static String _secret(int bytes) {
    final r = Random.secure();
    return List.generate(bytes, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<int> _freePort() async {
    final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = s.port;
    await s.close();
    return port;
  }

  /// Keeps the last lines of a process's output, for the diagnostics log.
  static List<String> _drain(Process p, String name) {
    final tail = <String>[];
    void add(String line) {
      if (line.trim().isEmpty) return;
      tail.add('$name: $line');
      if (tail.length > 20) tail.removeAt(0);
    }

    p.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(add, onError: (_) {});
    p.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(add, onError: (_) {});
    return tail;
  }

  static Future<bool> _waitPort(int port, Process p, Duration limit) async {
    final end = DateTime.now().add(limit);
    var exited = false;
    unawaited(p.exitCode.then((_) => exited = true));
    while (DateTime.now().isBefore(end) && !exited) {
      try {
        final s = await Socket.connect(InternetAddress.loopbackIPv4, port, timeout: const Duration(milliseconds: 300));
        s.destroy();
        return true;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    return false;
  }

  static Future<bool> _waitAdapter(Process p, Duration limit) async {
    final end = DateTime.now().add(limit);
    var exited = false;
    unawaited(p.exitCode.then((_) => exited = true));
    while (DateTime.now().isBefore(end) && !exited) {
      try {
        final list = await NetworkInterface.list(includeLinkLocal: false, type: InternetAddressType.IPv4);
        if (list.any((i) => i.addresses.any((a) => a.address == _tunAddress))) return true;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    return false;
  }

  @override
  Future<void> start({required String config, required List<String> bypassSubnets, String? dnsServer}) async {
    await stop();
    _stopping = false;
    final work = Directory(_work);
    await work.create(recursive: true);

    final socksPort = await _freePort();
    final apiPort = await _freePort();
    final user = _secret(8), pass = _secret(16), apiSecret = _secret(16);

    final String xrayJson;
    try {
      xrayJson = WindowsTunConfig.xray(config, port: socksPort, user: user, pass: pass);
    } catch (e) {
      throw VpnEngineException(VpnEngineError.config, 'xray config: $e');
    }
    final boxJson = WindowsTunConfig.singBox(
      socksPort: socksPort,
      user: user,
      pass: pass,
      xrayPath: xrayPath,
      singBoxPath: boxPath,
      apiPort: apiPort,
      apiSecret: apiSecret,
      serverHosts: WindowsTunConfig.serverHosts(config),
      bypassSubnets: bypassSubnets,
      dnsServer: dnsServer,
    );
    final xrayFile = File('${work.path}\\xray-${_secret(6)}.json');
    final boxFile = File('${work.path}\\box-${_secret(6)}.json');
    await xrayFile.writeAsString(xrayJson, flush: true);
    await boxFile.writeAsString(boxJson, flush: true);

    Future<void> fail(VpnEngineError error, String what, List<String> tail) async {
      _log('$what\n${tail.join('\n')}');
      await _killAll();
      for (final f in [xrayFile, boxFile]) {
        try {
          await f.delete();
        } catch (_) {}
      }
      throw VpnEngineException(error, what);
    }

    // 1. Xray: the server's config behind a private local SOCKS port.
    final xray = await Process.start(
      xrayPath,
      ['run', '-c', xrayFile.path],
      workingDirectory: dir,
      environment: {'XRAY_LOCATION_ASSET': dir},
    );
    _xray = xray;
    final xrayTail = _drain(xray, 'xray');
    if (!await _waitPort(socksPort, xray, const Duration(seconds: 10))) {
      await fail(VpnEngineError.config, 'Xray did not start', xrayTail);
    }

    // 2. sing-box: Wintun adapter, routes, DNS → Xray.
    final box = await Process.start(boxPath, ['run', '-c', boxFile.path, '-D', work.path], workingDirectory: dir);
    _box = box;
    final boxTail = _drain(box, 'sing-box');
    if (!await _waitAdapter(box, const Duration(seconds: 20))) {
      await fail(VpnEngineError.other, 'sing-box TUN did not come up', [...xrayTail, ...boxTail]);
    }

    // Both have read their configs (they hold credentials).
    for (final f in [xrayFile, boxFile]) {
      try {
        await f.delete();
      } catch (_) {}
    }
    try {
      await _pidFile.writeAsString('${xray.pid}\n${box.pid}', flush: true);
    } catch (_) {}

    _since = DateTime.now();
    _up = _down = _upSpeed = _downSpeed = 0;
    _watch(xray, 'xray', xrayTail);
    _watch(box, 'sing-box', boxTail);
    _listenTraffic(apiPort, apiSecret);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _emit(VpnPhase.connected));
    _emit(VpnPhase.connected);
    _log('Fast TUN connected (sing-box + Xray)');
  }

  void _watch(Process p, String name, List<String> tail) {
    p.exitCode.then((code) async {
      if (_stopping || (!identical(p, _xray) && !identical(p, _box))) return;
      _log('$name exited ($code)\n${tail.join('\n')}');
      await _teardown();
    });
  }

  void _listenTraffic(int port, String secret) {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    _api = client;
    () async {
      // sing-box's Clash API: one JSON line per second, {"up":..,"down":..}.
      for (var attempt = 0; attempt < 30 && identical(_api, client); attempt++) {
        try {
          final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port/traffic'));
          req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $secret');
          final res = await req.close();
          if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
          final done = Completer<void>();
          _traffic = res.transform(utf8.decoder).transform(const LineSplitter()).listen(
            (line) {
              try {
                final j = jsonDecode(line) as Map<String, dynamic>;
                _upSpeed = (j['up'] as num?)?.toInt() ?? 0;
                _downSpeed = (j['down'] as num?)?.toInt() ?? 0;
                _up += _upSpeed;
                _down += _downSpeed;
              } catch (_) {}
            },
            onDone: done.complete,
            onError: (_) => done.complete(),
          );
          await done.future;
        } catch (_) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
    }();
  }

  void _emit(VpnPhase phase) {
    if (_status.isClosed) return;
    final since = _since;
    _status.add(VpnStatusEvent(
      phase: phase,
      duration: since == null || phase != VpnPhase.connected ? 0 : DateTime.now().difference(since).inSeconds,
      uploadSpeed: phase == VpnPhase.connected ? _upSpeed : 0,
      downloadSpeed: phase == VpnPhase.connected ? _downSpeed : 0,
      upload: _up,
      download: _down,
    ));
  }

  Future<void> _killAll() async {
    _tick?.cancel();
    _tick = null;
    await _traffic?.cancel();
    _traffic = null;
    _api?.close(force: true);
    _api = null;
    // sing-box first: its routes and DNS go away with it.
    final box = _box, xray = _xray;
    _box = null;
    _xray = null;
    for (final p in [box, xray]) {
      if (p == null) continue;
      p.kill();
      await p.exitCode.timeout(const Duration(seconds: 3), onTimeout: () {
        p.kill(ProcessSignal.sigkill);
        return -1;
      });
    }
    try {
      if (await _pidFile.exists()) await _pidFile.delete();
    } catch (_) {}
  }

  Future<void> _teardown() async {
    final wasActive = _box != null || _xray != null;
    await _killAll();
    _since = null;
    if (wasActive) _emit(VpnPhase.disconnected);
  }

  @override
  Future<void> stop() async {
    _stopping = true;
    try {
      await _teardown();
    } finally {
      _stopping = false;
    }
  }

  @override
  Future<int?> connectedDelay(String url) async {
    if (!isActive) return null;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final watch = Stopwatch()..start();
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close().timeout(const Duration(seconds: 10));
      await res.drain<void>();
      watch.stop();
      return res.statusCode < 500 ? watch.elapsedMilliseconds : null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> cleanupStale() async {
    try {
      if (!await _pidFile.exists()) return;
      final pids = (await _pidFile.readAsLines()).map(int.tryParse).whereType<int>().toList();
      for (final pid in pids) {
        // Only our own executables: a reused PID may belong to anything.
        final r = await Process.run('tasklist', ['/FI', 'PID eq $pid', '/FO', 'CSV', '/NH']);
        final out = '${r.stdout}'.toLowerCase();
        if (out.contains('"xray.exe"') || out.contains('"sing-box.exe"')) Process.killPid(pid);
      }
      await _pidFile.delete();
    } catch (e) {
      debugPrint('stale tun cleanup: $e');
    }
  }

  final _logLines = <String>[];

  void _log(String text) {
    final stamp = DateTime.now().toIso8601String().substring(11, 23);
    for (final line in text.split('\n')) {
      if (line.trim().isEmpty) continue;
      _logLines.add('$stamp $line');
    }
    while (_logLines.length > 200) {
      _logLines.removeAt(0);
    }
  }

  @override
  String get log => _logLines.join('\n');
}
