import 'package:flutter/foundation.dart';

/// Build-time configuration. Values can be overridden with
/// `flutter run --dart-define-from-file=env.json` (see env.example.json).
abstract final class AppConfig {
  /// Login screen on/off. Off until the API exists: the app opens straight
  /// to Home with a local user. The login code is kept as it is; set this
  /// to true to bring it back.
  static const requireLogin = false;

  /// Optional subscription for the mock login's user. Empty by default:
  /// servers come from what you add on the Servers screen.
  static const devSubscriptionUrl = String.fromEnvironment('NOISE_SUB_URL');

  /// flutter_vless has native VPN backends only for these platforms.
  static bool get vpnSupported {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.macOS || TargetPlatform.windows => true,
      _ => false,
    };
  }

  static String get platformName {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  /// Apple Network Extension identifiers (needed once iOS/macOS VPN is set up).
  static const appleBundleId = 'com.noise.vpn.noisevpn';
  static const appleGroupId = 'group.com.noise.vpn.noisevpn';

  /// Probe target for ping through Xray.
  static const pingUrl = 'https://www.gstatic.com/generate_204';
}
