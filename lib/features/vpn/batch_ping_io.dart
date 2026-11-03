import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../servers/server_models.dart';
import 'batch_ping.dart';

BatchPinger createPlatformBatchPinger() => XrayBatchPinger();

/// One Xray process for the whole list: inbound `in<i>` on its own loopback
/// port routes to outbound `p<i>` (that server's own proxy outbound). Every
/// probe is a SOCKS5 CONNECT to the probe host plus an HTTP HEAD, timed until
/// the response line arrives, so a number means the config really works.
///
/// The Xray binary is the one flutter_vless already ships:
///   * Android: `libxray.so` in the app's native library dir,
///   * Windows: `xray\xray.exe` next to the app (same as flutter_vless),
///   * Linux: `xray` next to the app, in `xray/`, or on PATH.
/// iOS and macOS can't start child processes from a sandboxed app.
class XrayBatchPinger implements BatchPinger {
  static const _channel = MethodChannel('noisevpn/native');
  static const _probeHost = 'www.gstatic.com';
  static const _probePath = '/generate_204';
  static const _parallel = 16;

  String? _binary;
  bool _looked = false;

  Future<String?> _locate() async {
    if (_looked) return _binary;
    _looked = true;
    if (Platform.isIOS || Platform.isMacOS) return null;

    final candidates = <String>[];
    try {
      if (Platform.isAndroid) {
        final dir = await _channel.invokeMethod<String>('nativeLibraryDir');
        if (dir != null) candidates.add('$dir/libxray.so');
      } else {
        final sep = Platform.pathSeparator;
        final name = Platform.isWindows ? 'xray.exe' : 'xray';
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        candidates
          ..add('$exeDir${sep}xray$sep$name')
          ..add('$exeDir$sep$name')
          ..add('$exeDir${sep}data${sep}flutter_assets${sep}xray$sep$name');
        final path = Platform.environment['PATH'];
        if (path != null && !Platform.isWindows) {
          for (final d in path.split(':')) {
            if (d.isNotEmpty) candidates.add('$d$sep$name');
          }
        }
      }
    } catch (e) {
      debugPrint('xray lookup failed: $e');
    }

    for (final c in candidates) {
      if (await File(c).exists()) return _binary = c;
    }
    return null;
  }

  @override
  Future<bool> isAvailable() async => await _locate() != null;

  @override
  Future<bool> run(
    List<VpnServer> servers, {
    required Duration timeout,
    required void Function(String id, int? ms) onResult,
  }) async {
    final binary = await _locate();
    if (binary == null || servers.isEmpty) return false;

    final ports = <int>[];
    for (var i = 0; i < servers.length; i++) {
      final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      ports.add(s.port);
      await s.close();
    }

    final built = _buildConfig(servers, ports);
    if (built == null) return false;

    Directory? dir;
    Process? process;
    try {
      dir = await (await getTemporaryDirectory()).createTemp('noise-ping-');
      final file = File('${dir.path}${Platform.pathSeparator}ping.json');
      await file.writeAsString(built.json);

      process = await Process.start(binary, ['run', '-config', file.path], workingDirectory: dir.path);
      unawaited(process.stdout.drain<void>());
      unawaited(process.stderr.drain<void>());
      var exited = false;
      unawaited(process.exitCode.then((_) => exited = true));

      if (!await _waitReady(built.readyPort, () => exited)) {
        debugPrint('xray batch ping: core did not start');
        return false;
      }

      var next = 0;
      Future<void> worker() async {
        while (next < servers.length) {
          final i = next++;
          final ms = built.included.contains(i) ? await _probe(ports[i], timeout) : null;
          onResult(servers[i].id, ms);
        }
      }

      await Future.wait([for (var w = 0; w < math.min(_parallel, servers.length); w++) worker()]);
      return true;
    } catch (e) {
      debugPrint('xray batch ping failed: $e');
      return false;
    } finally {
      process?.kill();
      try {
        await dir?.delete(recursive: true);
      } catch (_) {}
    }
  }

  ({String json, int readyPort, Set<int> included})? _buildConfig(List<VpnServer> servers, List<int> ports) {
    final inbounds = <Map<String, dynamic>>[];
    final outbounds = <Map<String, dynamic>>[
      {'tag': 'direct', 'protocol': 'freedom'},
    ];
    final rules = <Map<String, dynamic>>[];
    final included = <int>{};

    for (var i = 0; i < servers.length; i++) {
      Map<String, dynamic>? proxy;
      try {
        final full = jsonDecode(servers[i].config) as Map<String, dynamic>;
        for (final o in (full['outbounds'] as List? ?? const [])) {
          if (o is! Map) continue;
          final protocol = o['protocol'];
          if (protocol == 'freedom' || protocol == 'blackhole' || protocol == 'dns') continue;
          proxy = Map<String, dynamic>.from(o);
          break;
        }
      } catch (_) {
        proxy = null;
      }
      if (proxy == null) continue;

      // Each server stands alone here: drop links to tags that don't exist.
      proxy
        ..['tag'] = 'p$i'
        ..remove('proxySettings');
      final stream = proxy['streamSettings'];
      if (stream is Map && stream['sockopt'] is Map) {
        final s = Map<String, dynamic>.from(stream);
        s['sockopt'] = Map<String, dynamic>.from(stream['sockopt'] as Map)..remove('dialerProxy');
        proxy['streamSettings'] = s;
      }

      inbounds.add({
        'tag': 'in$i',
        'listen': '127.0.0.1',
        'port': ports[i],
        'protocol': 'socks',
        'settings': {'auth': 'noauth', 'udp': false},
      });
      rules.add({
        'type': 'field',
        'inboundTag': ['in$i'],
        'outboundTag': 'p$i',
      });
      outbounds.add(proxy);
      included.add(i);
    }
    if (included.isEmpty) return null;

    final json = jsonEncode({
      'log': {'loglevel': 'none'},
      'inbounds': inbounds,
      'outbounds': outbounds,
      'routing': {'domainStrategy': 'AsIs', 'rules': rules},
    });
    return (json: json, readyPort: ports[included.first], included: included);
  }

  Future<bool> _waitReady(int port, bool Function() exited) async {
    for (var i = 0; i < 40; i++) {
      if (exited()) return false;
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

  Future<int?> _probe(int port, Duration timeout) async {
    Socket? socket;
    _Reader? reader;
    final watch = Stopwatch()..start();
    try {
      socket = await Socket.connect(InternetAddress.loopbackIPv4, port, timeout: timeout);
      socket.setOption(SocketOption.tcpNoDelay, true);
      final r = reader = _Reader(socket);
      final ok = await _exchange(socket, r).timeout(timeout - watch.elapsed);
      if (!ok) return null;
      final ms = watch.elapsedMilliseconds;
      return ms < 1 ? 1 : ms;
    } catch (_) {
      return null;
    } finally {
      socket?.destroy();
      try {
        await reader?.cancel();
      } catch (_) {}
    }
  }

  Future<bool> _exchange(Socket socket, _Reader reader) async {
    socket.add(const [5, 1, 0]); // SOCKS5, one method: no auth
    final hello = await reader.take(2);
    if (hello[0] != 5 || hello[1] != 0) return false;

    final host = ascii.encode(_probeHost);
    socket.add([5, 1, 0, 3, host.length, ...host, 0, 80]); // CONNECT host:80
    final head = await reader.take(4);
    if (head[1] != 0) return false;
    final addressLength = switch (head[3]) {
      1 => 4,
      4 => 16,
      _ => (await reader.take(1))[0],
    };
    await reader.take(addressLength + 2);

    socket.write('HEAD $_probePath HTTP/1.1\r\nHost: $_probeHost\r\nUser-Agent: NoiseVPN\r\nConnection: close\r\n\r\n');
    final status = await reader.line();
    return RegExp(r'^HTTP/1\.[01] [1-5]\d\d').hasMatch(status);
  }
}

/// Buffered reads over a socket stream.
class _Reader {
  _Reader(Stream<Uint8List> stream) : _it = StreamIterator(stream);

  final StreamIterator<Uint8List> _it;
  final _buffer = <int>[];

  Future<void> _fill() async {
    if (!await _it.moveNext()) throw const SocketException('closed');
    _buffer.addAll(_it.current);
  }

  Future<List<int>> take(int n) async {
    while (_buffer.length < n) {
      await _fill();
    }
    final out = _buffer.sublist(0, n);
    _buffer.removeRange(0, n);
    return out;
  }

  Future<String> line() async {
    while (true) {
      final i = _buffer.indexOf(10);
      if (i >= 0) {
        final text = String.fromCharCodes(_buffer.sublist(0, i)).trimRight();
        _buffer.removeRange(0, i + 1);
        return text;
      }
      if (_buffer.length > 4096) throw const FormatException('response line too long');
      await _fill();
    }
  }

  Future<void> cancel() => _it.cancel();
}
