import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class InstalledApp {
  const InstalledApp({required this.package, required this.label});

  final String package;
  final String label;
}

/// Apps with a launcher icon (Android only; empty elsewhere).
final installedAppsProvider = FutureProvider<List<InstalledApp>>((ref) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return const [];
  const channel = MethodChannel('noisevpn/native');
  final raw = await channel.invokeListMethod<Map<Object?, Object?>>('installedApps') ?? const [];
  return [
    for (final m in raw)
      if (m['package'] is String)
        InstalledApp(
          package: m['package'] as String,
          label: (m['label'] as String?)?.trim().isNotEmpty == true ? m['label'] as String : m['package'] as String,
        ),
  ];
});
