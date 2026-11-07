import 'dart:io';

String? _cached;
bool _looked = false;

String? bundledGeoAssetsDirectory() {
  if (_looked) return _cached;
  _looked = true;
  if (!Platform.isWindows) return null;
  try {
    final dir = Directory('${File(Platform.resolvedExecutable).parent.path}${Platform.pathSeparator}xray');
    final sep = Platform.pathSeparator;
    final complete = File('${dir.path}${sep}geoip.dat').existsSync() && File('${dir.path}${sep}geosite.dat').existsSync();
    // Only when both files are there: a folder without them would make every
    // geo rule fail, while the plugin's own copy step at least finds none.
    _cached = complete ? dir.absolute.path : null;
  } catch (_) {
    _cached = null;
  }
  return _cached;
}
