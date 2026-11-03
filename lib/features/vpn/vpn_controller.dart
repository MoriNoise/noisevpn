import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../servers/server_models.dart';
import '../servers/servers_controller.dart';
import 'vpn_backend.dart';

enum VpnFailure { unsupported, noServers, permissionDenied, startFailed }

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
  StreamSubscription<VpnStatusEvent>? _sub;
  Timer? _stopGuard;

  @override
  VpnState build() {
    final backend = ref.watch(vpnBackendProvider);
    _sub?.cancel();
    _sub = backend.status.listen(_onStatus);
    ref.onDispose(() {
      _sub?.cancel();
      _stopGuard?.cancel();
    });
    return const VpnState();
  }

  void _onStatus(VpnStatusEvent e) {
    // A late "connecting" from the engine must not undo a user's disconnect.
    if (state.phase == VpnPhase.disconnecting && e.phase == VpnPhase.connecting) return;
    if (e.phase == VpnPhase.disconnected) _stopGuard?.cancel();

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
    if (!backend.isSupported) {
      state = state.copyWith(failure: VpnFailure.unsupported);
      return;
    }
    state = state.copyWith(
      phase: VpnPhase.connecting,
      server: server,
      upload: 0,
      download: 0,
      duration: 0,
      clearFailure: true,
    );
    try {
      await backend.ensureInitialized();
      if (!await backend.requestPermission()) {
        state = state.copyWith(phase: VpnPhase.disconnected, failure: VpnFailure.permissionDenied);
        return;
      }
      await backend.start(remark: server.remark, config: server.config, disconnectLabel: disconnectLabel);
    } catch (e) {
      debugPrint('vpn start failed: $e');
      state = state.copyWith(phase: VpnPhase.disconnected, failure: VpnFailure.startFailed);
    }
  }

  Future<void> disconnect() async {
    if (state.phase == VpnPhase.disconnected) return;
    state = state.copyWith(phase: VpnPhase.disconnecting);
    // If the engine never confirms, don't leave the button stuck.
    _stopGuard?.cancel();
    _stopGuard = Timer(const Duration(seconds: 6), () {
      if (state.phase == VpnPhase.disconnecting) {
        state = state.copyWith(phase: VpnPhase.disconnected, uploadSpeed: 0, downloadSpeed: 0, duration: 0);
      }
    });
    try {
      await ref.read(vpnBackendProvider).stop();
    } catch (e) {
      debugPrint('vpn stop failed: $e');
    }
  }

  /// After the user picks another location while connected.
  Future<void> reconnect({required String disconnectLabel}) async {
    if (!state.isActive) return;
    final next = ref.read(resolvedServerProvider);
    if (next == null || next.id == state.server?.id) return;
    await ref.read(vpnBackendProvider).stop().catchError((_) {});
    await connect(disconnectLabel: disconnectLabel);
  }

  void clearFailure() => state = state.copyWith(clearFailure: true);
}

final vpnControllerProvider = NotifierProvider<VpnController, VpnState>(VpnController.new);
