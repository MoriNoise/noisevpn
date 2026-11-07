# Noise VPN

A free VPN client for Android, iOS, macOS and Windows, built with Flutter on
[flutter_vless](https://pub.dev/packages/flutter_vless) 1.1.7 (Xray core 26.10.31).

Supports VLESS (Reality, XHTTP), VMess, Trojan, Shadowsocks, SOCKS, Hysteria2 and
WireGuard. Import share links, subscriptions, WireGuard `.conf` files, raw Xray
JSON, sing-box JSON and Clash YAML.

## Run

```bash
flutter pub get
flutter run
```

Preview the phone layout on desktop: add `--dart-define=FORM_FACTOR=phone`.

## Platform setup

### Android

Ready. `minSdk` 23, `useLegacyPackaging`, INTERNET and the launcher-app query
are set. Release build:

```bash
flutter build apk --release --split-per-abi
```

Before publishing on Google Play, create a release signing key and fill in the
VPN declaration form in Play Console (needed for apps that use `VpnService`).

### Windows

Ready. The Xray runtime is already in `windows/xray/` and CMake copies it next
to the exe:

| File | Source |
| --- | --- |
| `xray.exe`, `geoip.dat`, `geosite.dat` | flutter_vless release `xray-windows-v26.10.31-r2` (SHA-256 checked) |
| `tun2socks.exe`, `wintun.dll` | flutter_vless example app |

VPN (TUN) mode needs the app to run as administrator. Proxy-only mode doesn't.

### macOS (needs a Mac with Xcode)

Run once from the project root, with your Apple Team ID:

```bash
flutter pub get
dart run flutter_vless:setup_macos_vpn \
  --bundle-id com.noise.vpn.noisevpn \
  --group-id group.com.noise.vpn.noisevpn \
  --team-id YOUR_TEAM_ID
open macos/Runner.xcworkspace
```

In Xcode, select your Team on both `Runner` and `XrayTunnel`, then
`flutter run -d macos`. The command is safe to run again after upgrades.

### iOS (needs a Mac with Xcode and a real iPhone)

`Runner` already has its entitlements (`ios/Runner/Runner.entitlements`) and the
Keychain group in `Info.plist`. The Packet Tunnel target has to be added in Xcode:

1. `flutter pub get`, then `flutter build ios --config-only`, then open
   `ios/Runner.xcworkspace`.
2. **File → New → Target… → Network Extension**. Name it `XrayTunnel`,
   language Swift, Provider Type **Packet Tunnel**. When Xcode asks to activate
   the scheme, choose **Activate**.
3. Replace the three files Xcode created in `ios/XrayTunnel/` with the ones in
   `ios/XrayTunnel_template/` (`PacketTunnelProvider.swift`, `Info.plist`,
   `XrayTunnel.entitlements`). Then delete the `XrayTunnel_template` folder.
4. Select the `XrayTunnel` target:
   - **General**: Minimum Deployments iOS **15.0**. Bundle Identifier
     `com.noise.vpn.noisevpn.XrayTunnel`.
   - **Build Settings**: Code Signing Entitlements =
     `XrayTunnel/XrayTunnel.entitlements`.
   - **General → Frameworks and Libraries → + → Add Other… → Add Package
     Dependency… → Add Local…** and pick the folder Flutter generated at
     `ios/Flutter/ephemeral/Packages/.packages/flutter_vless-1.1.7` (the one that
     contains `Package.swift`). Add the product **flutter-vless-tunnel-support**
     to `XrayTunnel` only, not to `Runner`.
5. **Signing & Capabilities**: select your Team on both `Runner` and
   `XrayTunnel`. Both must show **App Groups** (`group.com.noise.vpn.noisevpn`)
   and **Network Extensions** (Packet Tunnel). Register the App Group in your
   Apple Developer account if Xcode asks.
6. Run on a real iPhone (the simulator can't run VPN tunnels).

The example project in the flutter_vless repository (`example/ios`) has a
working `XrayTunnel` target to compare against.

### Linux and web

flutter_vless has no engine there. The server list works; Connect is disabled
with a notice. Ping works on Linux when an `xray` binary is next to the app, in
`xray/`, or on PATH.

## Settings

- **Connection**: VPN or proxy-only (with SOCKS port), per-app proxy (Android),
  bypass LAN, DNS through the tunnel (Android), DNS server (Auto, Cloudflare,
  Google, Quad9, AdGuard, custom), bypass Iranian sites, block ads (Android and
  Windows), TLS fragment.
- **Advanced**: auto-reconnect (attempts, longest pause), On Demand (Apple),
  kill switch info, Android Always-on status and requirement, notification
  button (Android), quick toggle (Android tile, macOS menu bar, Windows tray),
  diagnostics log and a live connection test.

Settings that change the engine apply right away when disconnected, and on the
next connect otherwise.

## Ping

Ping is a real request through each server's own config, 5 s timeout each. All
servers are tested at once through one Xray process (an inbound per server), the
way v2rayNG and Happ do it. The Xray binary is the one flutter_vless ships:
`libxray.so` on Android, `xray/xray.exe` on Windows. If that engine can't
start, the app falls back to flutter_vless's own probe, one server at a time.

## Publishing for free

- **Google Play**: VPN apps must fill in the VPN declaration and have a privacy
  policy URL.
- **App Store**: Apple only accepts VPN apps from developer accounts enrolled as
  an **organization**, not as an individual. A privacy policy is required.
- Keep the flutter_vless MIT license notice (see its `NOTICE`) and Xray's
  license (`windows/xray/LICENSE.xray-core`) with your releases.
