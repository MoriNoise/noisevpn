import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noisevpn/app.dart';
import 'package:noisevpn/core/prefs.dart';
import 'package:noisevpn/features/servers/server_models.dart';
import 'package:noisevpn/features/shell/app_shell.dart';
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
  Future<void> start({required String remark, required String config, required String disconnectLabel}) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<int?> delay(VpnServer server) async => null;
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
