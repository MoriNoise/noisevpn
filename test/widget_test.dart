import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_vless/flutter_vless.dart' show VlessOptions;
import 'package:noisevpn/app.dart';
import 'package:noisevpn/core/prefs.dart';
import 'package:noisevpn/features/servers/server_models.dart';
import 'package:noisevpn/features/servers/wireguard.dart';
import 'package:noisevpn/features/shell/app_shell.dart';
import 'package:noisevpn/features/vpn/config_tweaks.dart';
import 'package:noisevpn/features/vpn/vpn_backend.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test double only; the app itself never simulates a connection.
class _TestBackend implements VpnBackend {
  @override
  bool get isSupported => true;
  @override
  Stream<VpnStatusEvent> get status => const Stream.empty();
  @override
  Future<void> ensureInitialized() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> start({
    required String remark,
    required String config,
    required String disconnectLabel,
    VpnStartOptions options = const VpnStartOptions(),
  }) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<bool?> isSessionAlive() async => false;
  @override
  Future<int?> delay(VpnServer server) async => null;
  @override
  void setOptions(VlessOptions options) {}
  @override
  String? get optionsError => null;
  @override
  Future<int?> connectedDelay() async => null;
  @override
  Future<EngineCapabilities?> capabilities() async => null;
  @override
  Future<QuickTileResult> addQuickTile() async => QuickTileResult.unsupported;
  @override
  Future<void> clearQuickAccess() async {}
  @override
  Future<String?> coreVersion() async => null;
  @override
  Future<String> diagnostics() async => '';
  @override
  void dispose() {}
}

const _link =
    'vless://0b064465-ceb0-4793-9071-00251ceaee92@example.com:443?encryption=none&type=raw&security=tls&sni=example.com#%F0%9F%87%A9%F0%9F%87%AA%20DE%20direct';

void main() {
  group('parsing', () {
    test('flag decides the country, text after the code is the tag', () {
      final us = RemarkInfo.parse('🇺🇸 US AI Ready');
      expect(us.countryCode, 'US');
      expect(us.tag, 'AI Ready');
      expect(RemarkInfo.parse('🇸🇪 SW').countryCode, 'SE');
      expect(RemarkInfo.parse(' 🇦🇱 AL').countryCode, 'AL');
      expect(RemarkInfo.parse('Backup server').countryCode, isNull);
    });

    test('subscription-userinfo header', () {
      final u = SubscriptionUsage.parse('upload=100; download=900; total=2000; expire=0')!;
      expect(u.used, 1000);
      expect(u.fraction, 0.5);
      expect(SubscriptionUsage.parse('upload=1; download=1; total=0')!.unlimited, isTrue);
    });

    test('pasted share link becomes a server', () {
      final servers = parseSubscription(_link, sourceId: localSourceId);
      expect(servers, hasLength(1));
      expect(servers.single.countryCode, 'DE');
      expect(servers.single.tag, 'direct');
    });

    test('WireGuard link and .conf are imported next to other links', () {
      const pk = 'yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk=';
      const pub = 'xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=';
      final link = 'wireguard://${Uri.encodeComponent(pk)}@162.159.192.1:2408'
          '?publickey=${Uri.encodeComponent(pub)}&address=172.16.0.2&reserved=1,2,3#WARP';
      const conf = '[Interface]\nPrivateKey = $pk\nAddress = 10.8.0.2/24\n\n'
          '[Peer]\nPublicKey = $pub\nEndpoint = wg.example.com:51820\n';
      final servers = parseSubscription('$_link\n$link\n$conf', sourceId: localSourceId);
      expect(servers, hasLength(3));
      expect(servers.where((s) => s.protocol == 'wireguard'), hasLength(2));
      // The stored link parses back to the same server.
      final wg = servers.firstWhere((s) => s.remark == 'WARP');
      expect(parseSubscription(wg.shareLink, sourceId: localSourceId).single.id, wg.id);
      expect(WireGuardProfile.fromLink(wg.shareLink)!.reserved, [1, 2, 3]);
    });

    test('config tweaks add rules only when switched on', () {
      final config = parseSubscription(_link, sourceId: localSourceId).single.config;
      expect(const ConfigTweaks().apply(config), config);
      final tweaked = const ConfigTweaks(bypassIran: true, geoData: false).apply(config);
      expect(tweaked, contains(r'regexp:\\.ir$'));
      expect(tweaked, isNot(contains('geoip:')));
    });
  });

  testWidgets('opens straight to the app and shows the empty server list', (tester) async {
    SharedPreferences.setMockInitialValues({'app.locale': 'en'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          vpnBackendProvider.overrideWithValue(_TestBackend()),
        ],
        child: const NoiseApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);

    await tester.tap(find.text('Servers').last);
    await tester.pumpAndSettle();
    expect(find.text('No servers yet'), findsOneWidget);
  });
}
