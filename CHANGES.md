# Changes in this update

Use this as a fresh project folder. Don't unzip it over the old one: deleted
files would stay behind.

## Deleted
- `lib/features/auth/` (login screen, auth controller, mock and real repository)
- `lib/core/widgets/orbit_ring.dart` (only the login screen used it)

## New
- `lib/features/servers/wireguard.dart`: WireGuard links and `.conf` import
- `lib/features/vpn/config_tweaks.dart`: DNS, routing rules, TLS fragment
- `lib/features/vpn/engine_info.dart`: engine capabilities and Xray version
- `lib/features/settings/advanced_tab.dart`: the new Advanced tab
- `lib/features/settings/settings_widgets.dart`: shared settings widgets
- `windows/xray/`: Windows runtime (xray.exe, tun2socks.exe, wintun.dll, geo data)
- `ios/Runner/Runner.entitlements`, `ios/XrayTunnel_template/`
- `CHANGES.md`

## Changed
- `lib/app.dart`, `lib/features/shell/app_shell.dart`: no login, opens on Home
- `lib/core/config/app_config.dart`: removed `requireLogin` and `devSubscriptionUrl`
- `lib/core/l10n/strings.dart`: removed login text, added new settings text (EN + FA)
- `lib/features/vpn/*`: flutter_vless 1.1.7 options, error codes, iOS LAN fix
- `lib/features/settings/settings_screen.dart`: DNS and routing cards, Advanced tab
- `lib/features/servers/server_models.dart`: WireGuard in `parseSubscription`
- `lib/features/home/home_screen.dart`: messages for the new error types
- `android/.../MainActivity.kt`: `openVpnSettings` channel method
- `ios/Runner.xcodeproj/project.pbxproj`: Runner entitlements in all three configs
- `ios/Runner/Info.plist`: `FlutterVlessKeychainAccessGroup`
- `test/widget_test.dart`: new backend methods, WireGuard and tweak tests
- `README.md`, `NOISE_VPN_GUIDE.md`
