import '../servers/server_models.dart';
import 'batch_ping.dart';

BatchPinger createPlatformBatchPinger() => _NoBatchPinger();

class _NoBatchPinger implements BatchPinger {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> run(
    List<VpnServer> servers, {
    required Duration timeout,
    required void Function(String id, int? ms) onResult,
  }) async =>
      false;
}
