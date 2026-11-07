import 'geo_assets_stub.dart' if (dart.library.io) 'geo_assets_io.dart' as impl;

/// The folder holding geoip.dat and geosite.dat that ship with the Windows
/// app (`xray\` next to the exe), or null anywhere else.
///
/// Passed to flutter_vless as `geoAssetsDirectory` on Windows. Without it,
/// every TUN connect copies both files (about 27 MB) into a fresh private
/// folder in C:\Windows\Temp before Xray can start.
String? bundledGeoAssetsDirectory() => impl.bundledGeoAssetsDirectory();
