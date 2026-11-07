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

## Faster Windows TUN connect
- New `lib/features/vpn/geo_assets.dart` (+ `geo_assets_io.dart`, `geo_assets_stub.dart`):
  finds the app's own `xray\` folder on Windows.
- `lib/features/vpn/flutter_vless_backend.dart`: passes it as `geoAssetsDirectory`,
  so flutter_vless no longer copies geoip.dat + geosite.dat (about 27 MB) into a
  new private folder in C:\Windows\Temp on every TUN connect.

## Windows fast TUN engine (sing-box + Xray)
- New `lib/features/vpn/windows_tun.dart`, `windows_tun_io.dart`, `windows_tun_stub.dart`,
  `windows_tun_config.dart`: Xray runs the server config behind a private,
  password-protected local SOCKS port; sing-box 1.14.4 owns the Wintun adapter,
  routes and DNS (like v2rayN). Both run from the app's `xray\` folder, so
  antivirus scans them once instead of on every connect.
- `flutter_vless_backend.dart`: Windows VPN mode uses it unless Strict mode is on.
  Proxy mode and Strict mode still use flutter_vless.
- `vpn_settings.dart`, `vpn_backend.dart`, `vpn_controller.dart`, `settings_screen.dart`,
  `advanced_tab.dart`, `strings.dart`: "Strict mode (kill switch)" switch (Windows,
  Settings → Connection), off by default.
- `windows/xray/sing-box.exe`, `LICENSE.sing-box`, `SOURCES.txt`; `windows/CMakeLists.txt`
  requires sing-box.exe; the CI workflow downloads it, pinned by SHA-256.

## TUN engine selector (Windows)
- `settings_screen.dart`, `strings.dart`: the "Strict mode" switch is now a
  two-option selector, "TUN engine: sing-box (fast) | flutter_vless (kill switch)",
  with a hint under it for the chosen engine. Same setting (`windowsStrictTun`).

## Desktop Home with locations, and the connect animation
- New `lib/features/home/server_panel.dart`: locations panel on desktop Home (search,
  test ping, fastest location, servers grouped by subscription). One click selects;
  while connected it switches to that server. Adding and editing stays on Servers.
- `lib/features/home/home_screen.dart`: when the page is at least 1000 px wide (and
  640 px tall), Home is two columns: connect card (button above status and current
  location), speeds and plan on the left, locations on the right. Narrower windows
  keep the previous layout; phones are unchanged.
- `lib/features/home/connect_button.dart`: while connecting, radar waves pulse from
  the button to the ring, two dots orbit and the button breathes; when it connects,
  a double green shockwave, a particle burst, a pop and (phones) a short vibration.
  Skipped when the system asks for reduced motion.
- `lib/core/l10n/strings.dart`: panel text (EN + FA).
