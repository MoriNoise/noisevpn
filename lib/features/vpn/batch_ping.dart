import '../servers/server_models.dart';
import 'batch_ping_stub.dart' if (dart.library.io) 'batch_ping_io.dart';

/// Tests many servers at once through one Xray process, like v2rayNG and
/// Happ do. Each result is a real request through that server's config.
abstract interface class BatchPinger {
  /// Whether an Xray binary was found on this device.
  Future<bool> isAvailable();

  /// Runs all probes in parallel; [onResult] fires as each one finishes
  /// (null ms = no answer within [timeout]). Returns false when the batch
  /// engine couldn't start, so the caller can fall back.
  Future<bool> run(
    List<VpnServer> servers, {
    required Duration timeout,
    required void Function(String id, int? ms) onResult,
  });
}

BatchPinger createBatchPinger() => createPlatformBatchPinger();
