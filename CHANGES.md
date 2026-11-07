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

## Fix: Windows timeouts, Android Bypass LAN
- `lib/features/vpn/vpn_controller.dart`: Windows and macOS get 90 s for `start()`
  and 100 s for the whole attempt (was 15 s / 25 s), so sessions that were still
  starting aren't cancelled. Bypass LAN on Android now uses Xray direct rules.
- `lib/features/vpn/flutter_vless_backend.dart`: `bypassSubnets` is no longer sent
  on Android (flutter_vless 1.1.7 rejects `10.0.0.0/8` there).
- `lib/features/vpn/vpn_backend.dart`: comment only.

## Subscriptions: edit and auto-update
- `lib/features/servers/server_models.dart`, `servers_controller.dart`,
  `add_source_sheet.dart`, `servers_screen.dart`, `lib/core/l10n/strings.dart`.

## Windows build fix (LNK1327)
- `windows/runner/CMakeLists.txt`: `/MANIFESTUAC:NO`, so the linker doesn't add a
  second UAC level next to the manifest's `requireAdministrator`.

## Fix: Windows stuck on "connecting" (the real cause)
- `windows/runner/flutter_window.cpp`: `SetChildContent()` now runs before
  `RegisterPlugins()`. flutter_vless 1.1.7 on Windows caches the main window at
  registration (`GetAncestor(view, GA_ROOT)`) and posts every start/stop result
  and status update to it. Flutter creates the view under `HWND_MESSAGE`, so
  with the old order the plugin cached the wrong window and every message was
  dropped: the native side connected, the app never heard about it.
