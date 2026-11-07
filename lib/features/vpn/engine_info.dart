import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vpn_backend.dart';

/// What the loaded engine supports. Invalidate after engine options change.
final engineCapabilitiesProvider = FutureProvider<EngineCapabilities?>((ref) {
  return ref.watch(vpnBackendProvider).capabilities();
});

/// The Xray version the native runtime reports (null when unknown).
final coreVersionProvider = FutureProvider<String?>((ref) {
  return ref.watch(vpnBackendProvider).coreVersion();
});

/// Opens Android's VPN settings (Always-on is chosen there). False when it
/// couldn't be opened or on other platforms.
Future<bool> openSystemVpnSettings() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    return await const MethodChannel('noisevpn/native').invokeMethod<bool>('openVpnSettings') ?? false;
  } catch (_) {
    return false;
  }
}
