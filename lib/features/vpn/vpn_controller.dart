import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/prefs.dart';
import '../servers/server_models.dart';
import '../servers/servers_controller.dart';
import 'installed_apps.dart';
import 'vpn_backend.dart';
import 'vpn_settings.dart';

enum VpnFailure {
  unsupported,
  noServers,
  permissionDenied,

  /// Windows VPN mode: the app isn't elevated. flutter_vless's
  /// requestPermission() there only reports elevation, it can't grant it.
  needsAdmin,
  startFailed,
  timeout,
}

@immutable
class VpnState {
  const VpnState({
    this.phase = VpnPhase.disconnected,
    this.server,
    this.duration = 0,
    this.uploadSpeed = 0,
    this.downloadSpeed = 0,
    this.upload = 0,
    this.download = 0,
    this.failure,
  });

  final VpnPhase phase;

  /// The server of the current (or last attempted) session.
  final VpnServer? server;
  final int duration;
  final int uploadSpeed;
  final int downloadSpeed;
  final int upload;
  final int download;
  final VpnFailure? failure;

  bool get isActive => phase == VpnPhase.connected || phase == VpnPhase.connecting;

  VpnState copyWith({
    VpnPhase? phase,
    VpnServer? server,
    int? duration,
    int? uploadSpeed,
    int? downloadSpeed,
    int? upload,
    int? download,
    VpnFailure? failure,
    bool clearFailure = false,
  }) {
    return VpnState(
      phase: phase ?? this.phase,
      server: server ?? this.server,
      duration: duration ?? this.duration,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      upload: upload ?? this.upload,
      download: download ?? this.download,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class VpnController extends Notifier<VpnState> {
  static const _lastServerKey = 'vpn.lastServerId';

  /// No status for this long while "connected" means: go and check.
  static const _silence = Duration(seconds: 6);

  /// Right after the user connects or disconnects, the service is still
  /// starting or stopping; don't second-guess it during this window.
  static const _grace = Duration(seconds: 10);

  /// Engine setup and start() must answer within this; some ROMs (HyperOS,
  /// MIUI) never complete the platform call instead of throwing.
  static const _callTimeout = Duration(seconds: 15);

  /// The system VPN dialog waits on the user, so it gets longer.
  static const _permissionTimeout = Duration(seconds: 60);

  /// From a granted permission to the engine's "connected".
  static const _connectTimeout = Duration(seconds: 25);

  StreamSubscription<VpnStatusEvent>? _sub;
  Timer? _stopGuard;
  Timer? _watchdog;
  Timer? _connectGuard;

  /// Bumped on every connect/disconnect, so a slow call from an older
  /// attempt can't change the state of a newer one.
  int _attempt = 0;

  /// Set while an attempt has called start() and waits for "connected".
  DateTime? _awaitingSince;
  AppLifecycleListener? _lifecycle;
  DateTime _lastEvent = DateTime.now();
  DateTime _lastCommand = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  VpnState build() {
    final backend = ref.watch(vpnBackendProvider);
    _sub?.cancel();
    _sub = backend.status.listen(_onStatus);
    _lifecycle?.dispose();
    _lifecycle = AppLifecycleListener(onResume: verify, onExitRequested: _onExitRequested);
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) {
      if (state.phase != VpnPhase.disconnected && DateTime.now().difference(_lastEvent) > _silence) verify();
    });
    ref.onDispose(() {
      _sub?.cancel();
      _stopGuard?.cancel();
      _connectGuard?.cancel();
      _watchdog?.cancel();
      _lifecycle?.dispose();
    });

    // Listen for status from launch, not only after the first Connect, so a
    // session that is already running (or that ended meanwhile) shows up.
    Future.microtask(() async {
      try {
        await backend.ensureInitialized();
      } catch (e) {
        debugPrint('vpn init at launch failed: $e');
      }
      await verify();
    });
    return const VpnState();
  }

  /// Brings the screen in line with what is really running. Called on
  /// launch, when the app comes back to the foreground, and when status
  /// updates stop arriving.
  Future<void> verify() async {
    if (DateTime.now().difference(_lastCommand) < _grace) return;
    // Still in setup or on the system VPN dialog: there is no service yet,
    // and the connect timeouts cover this part.
    if (state.phase == VpnPhase.connecting && _awaitingSince == null) return;
    final alive = await ref.read(vpnBackendProvider).isSessionAlive();
    if (alive == null) return;

    if (!alive && state.phase != VpnPhase.disconnected) {
      final wasConnecting = state.phase == VpnPhase.connecting;
      _stopGuard?.cancel();
      _attempt++;
      _endAttempt();
      state = state.copyWith(
        phase: VpnPhase.disconnected,
        uploadSpeed: 0,
        downloadSpeed: 0,
        duration: 0,
        // The service went away before ever connecting: say so.
        failure: wasConnecting ? VpnFailure.startFailed : null,
      );
    } else if (alive && state.phase == VpnPhase.disconnected) {
      // Running from before the app was (re)opened. Status updates fill in
      // the numbers; the server is the one last connected.
      state = state.copyWith(phase: VpnPhase.connected, server: state.server ?? _lastServer());
    }
  }

  /// Closing the window on desktop. On Windows the plugin keeps its
  /// traffic barrier after the app exits without an explicit stop, which
  /// leaves the machine without internet, so stop first.
  Future<AppExitResponse> _onExitRequested() async {
    if (state.phase != VpnPhase.disconnected) {
      _attempt++;
      _endAttempt();
      try {
        await ref.read(vpnBackendProvider).stop().timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('vpn stop on exit failed: $e');
      }
    }
    return AppExitResponse.exit;
  }

  VpnServer? _lastServer() {
    final id = ref.read(sharedPreferencesProvider).getString(_lastServerKey);
    if (id == null) return null;
    for (final s in ref.read(serversControllerProvider).servers) {
      if (s.id == id) return s;
    }
    return null;
  }

  void _onStatus(VpnStatusEvent e) {
    _lastEvent = DateTime.now();
    // A late "connecting" from the engine must not undo a user's disconnect,
    // nor bring back the spinner after a timeout or a failed start.
    if (e.phase == VpnPhase.connecting &&
        (state.phase == VpnPhase.disconnecting || (state.phase == VpnPhase.disconnected && _awaitingSince == null))) {
      return;
    }
    if (e.phase == VpnPhase.disconnected) _stopGuard?.cancel();

    if (e.phase == VpnPhase.disconnected && state.phase == VpnPhase.connecting) {
      final since = _awaitingSince;
      // Early or before start(): the "disconnected" of the session we just
      // stopped (restart, reconnect). Not about this attempt.
      if (since == null || DateTime.now().difference(since) < const Duration(seconds: 2)) return;
      // The engine gave up on its own while we waited for it.
      _attempt++;
      _endAttempt();
      state = state.copyWith(
        phase: VpnPhase.disconnected,
        uploadSpeed: 0,
        downloadSpeed: 0,
        duration: 0,
        failure: VpnFailure.startFailed,
      );
      return;
    }
    if (e.phase == VpnPhase.connected || e.phase == VpnPhase.disconnected) _endAttempt();

    final live = e.phase == VpnPhase.connected;
    state = state.copyWith(
      phase: e.phase,
      duration: live ? e.duration : (e.phase == VpnPhase.disconnected ? 0 : state.duration),
      uploadSpeed: live ? e.uploadSpeed : 0,
      downloadSpeed: live ? e.downloadSpeed : 0,
      upload: live ? e.upload : state.upload,
      download: live ? e.download : state.download,
      clearFailure: live,
    );
  }

  /// Connects, or disconnects when a session is active or starting.
  Future<void> toggle({required String disconnectLabel}) async {
    switch (state.phase) {
      case VpnPhase.disconnected:
        await connect(disconnectLabel: disconnectLabel);
      case VpnPhase.connecting:
      case VpnPhase.connected:
        await disconnect();
      case VpnPhase.disconnecting:
        break;
    }
  }

  Future<void> connect({required String disconnectLabel}) async {
    final server = ref.read(resolvedServerProvider);
    if (server == null) {
      state = state.copyWith(failure: VpnFailure.noServers);
      return;
    }
    final backend = ref.read(vpnBackendProvider);
    _lastCommand = DateTime.now();
    if (!backend.isSupported) {
      state = state.copyWith(failure: VpnFailure.unsupported);
      return;
    }
    _endAttempt();
    final attempt = ++_attempt;
    bool current() => attempt == _attempt;

    state = state.copyWith(
      phase: VpnPhase.connecting,
      server: server,
      upload: 0,
      download: 0,
      duration: 0,
      clearFailure: true,
    );
    try {
      await backend.ensureInitialized().timeout(_callTimeout);
      if (!current()) return;

      final options = await _options();
      if (!current()) return;

      // Proxy-only opens no tunnel, so it needs neither the Android VPN
      // dialog nor administrator rights on Windows.
      if (!options.proxyOnly) {
        final granted = await backend.requestPermission().timeout(_permissionTimeout);
        if (!current()) return;
        if (!granted) {
          final windows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
          state = state.copyWith(
            phase: VpnPhase.disconnected,
            failure: windows ? VpnFailure.needsAdmin : VpnFailure.permissionDenied,
          );
          return;
        }
      }

      // Started before start() so a start() that never returns is covered too.
      _awaitingSince = DateTime.now();
      _connectGuard?.cancel();
      _connectGuard = Timer(_connectTimeout, () => _giveUp(attempt, VpnFailure.timeout));

      await backend
          .start(
            remark: server.remark,
            config: server.config,
            disconnectLabel: disconnectLabel,
            options: options,
          )
          .timeout(_callTimeout);
      if (!current()) return;
      _lastEvent = DateTime.now();
      await ref.read(sharedPreferencesProvider).setString(_lastServerKey, server.id);
    } on TimeoutException catch (e) {
      debugPrint('vpn start timed out: $e');
      await _giveUp(attempt, VpnFailure.timeout);
    } catch (e) {
      debugPrint('vpn start failed: $e');
      await _giveUp(attempt, VpnFailure.startFailed);
    }
  }

  void _endAttempt() {
    _connectGuard?.cancel();
    _connectGuard = null;
    _awaitingSince = null;
  }

  /// Ends a connect attempt that won't succeed: error on screen, engine
  /// stopped, button usable again.
  Future<void> _giveUp(int attempt, VpnFailure failure) async {
    if (attempt != _attempt || state.phase != VpnPhase.connecting) return;
    _attempt++; // anything still in flight for this attempt is now stale
    _endAttempt();
    _lastCommand = DateTime.now();
    state = state.copyWith(
      phase: VpnPhase.disconnected,
      uploadSpeed: 0,
      downloadSpeed: 0,
      duration: 0,
      failure: failure,
    );
    // Don't let a half-started engine keep running; don't wait on it either.
    unawaited(ref.read(vpnBackendProvider).stop().timeout(_callTimeout).catchError((Object e) {
      debugPrint('vpn stop after failed start: $e');
    }));
  }

  /// Turns Settings → Connection into flutter_vless options.
  Future<VpnStartOptions> _options() async {
    final settings = ref.read(vpnSettingsProvider);
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    var blocked = <String>[];
    if (android && !settings.proxyOnly && settings.selectedApps.isNotEmpty) {
      switch (settings.perAppMode) {
        case PerAppMode.off:
          break;
        case PerAppMode.bypass:
          blocked = settings.selectedApps.toList();
        case PerAppMode.only:
          try {
            final apps = await ref.read(installedAppsProvider.future);
            blocked = [
              for (final a in apps)
                if (!settings.selectedApps.contains(a.package)) a.package,
            ];
          } catch (e) {
            // Without the app list everything stays in the tunnel.
            debugPrint('installed apps unavailable: $e');
          }
      }
    }
    return VpnStartOptions(
      proxyOnly: settings.proxyOnly,
      socksPort: settings.socksPort,
      blockedApps: blocked,
      bypassSubnets: settings.bypassLan ? VpnSettings.lanSubnets : const [],
      dnsThroughTunnel: settings.dnsThroughTunnel,
    );
  }

  /// Applies changed settings to a running session.
  Future<void> restart({required String disconnectLabel}) async {
    if (!state.isActive) return;
    await ref.read(vpnBackendProvider).stop().timeout(_callTimeout).catchError((_) {});
    await connect(disconnectLabel: disconnectLabel);
  }

  Future<void> disconnect() async {
    if (state.phase == VpnPhase.disconnected) return;
    _lastCommand = DateTime.now();
    _attempt++; // a connect still in progress must not go on after this
    _endAttempt();
    state = state.copyWith(phase: VpnPhase.disconnecting);
    // If the engine never confirms, don't leave the button stuck.
    _stopGuard?.cancel();
    _stopGuard = Timer(const Duration(seconds: 6), () {
      if (state.phase == VpnPhase.disconnecting) {
        state = state.copyWith(phase: VpnPhase.disconnected, uploadSpeed: 0, downloadSpeed: 0, duration: 0);
      }
    });
    try {
      await ref.read(vpnBackendProvider).stop().timeout(_callTimeout);
    } catch (e) {
      debugPrint('vpn stop failed: $e');
    }
  }

  /// After the user picks another location while connected.
  Future<void> reconnect({required String disconnectLabel}) async {
    if (!state.isActive) return;
    final next = ref.read(resolvedServerProvider);
    if (next == null || next.id == state.server?.id) return;
    await ref.read(vpnBackendProvider).stop().timeout(_callTimeout).catchError((_) {});
    await connect(disconnectLabel: disconnectLabel);
  }

  void clearFailure() => state = state.copyWith(clearFailure: true);
}

final vpnControllerProvider = NotifierProvider<VpnController, VpnState>(VpnController.new);
