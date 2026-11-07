import 'package:flutter/foundation.dart';

/// Build-time configuration.
abstract final class AppConfig {
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

  /// Apple Network Extension identifiers. The tunnel extension is
  /// `<appleBundleId>.XrayTunnel`; both targets share [appleGroupId].
  static const appleBundleId = 'com.noise.vpn.noisevpn';
  static const appleGroupId = 'group.com.noise.vpn.noisevpn';

  /// Probe target for ping through Xray.
  static const pingUrl = 'https://www.gstatic.com/generate_204';
}
