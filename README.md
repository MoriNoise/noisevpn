# Noise VPN

Flutter client on flutter_vless 1.1.6 (Xray core).

## Run

```bash
flutter pub get
flutter run
```

The mock login uses `https://vpn.morinoise.ir:2096/sub/mori` by default.
To use another link without editing code, copy `env.example.json` to
`env.json` (git-ignored) and run `flutter run --dart-define-from-file=env.json`.

Demo login: `demo` / `demo1234`.

Preview the phone layout on desktop: add `--dart-define=FORM_FACTOR=phone`.

## Platforms

- **Android**: ready. `minSdk` 23, `useLegacyPackaging` and INTERNET are set.
- **Windows**: put the Xray runtime next to the exe in a `xray/` folder
  (`xray.exe`, `tun2socks.exe`, `wintun.dll`, `geoip.dat`, `geosite.dat`).
  VPN mode needs the app to run as administrator.
- **iOS / macOS**: need a Packet Tunnel extension, an App Group
  (`group.com.noise.vpn.noisevpn`) and signing. See the flutter_vless
  platform guides. Until then the VPN can't start there.
- **Linux / web**: flutter_vless has no backend, so Connect and ping are
  disabled. The server list is the real subscription.

## Ping

Ping is a real request through each server's own config, 5 s timeout each.
All servers are tested at once through one Xray process (an inbound per
server), the way v2rayNG and Happ do it. The Xray binary is the one
flutter_vless ships: `libxray.so` on Android, `xray/xray.exe` on Windows.
On Linux, put `xray` next to the app, in `xray/`, or on PATH.

If that engine can't start, the app falls back to flutter_vless's own
probe, which tests one server at a time.
