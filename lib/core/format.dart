/// Number formatting shared by the home and servers screens.
abstract final class Fmt {
  static const _units = ['B', 'KB', 'MB', 'GB', 'TB'];

  static String bytes(int value) {
    if (value <= 0) return '0 B';
    var v = value.toDouble();
    var i = 0;
    while (v >= 1024 && i < _units.length - 1) {
      v /= 1024;
      i++;
    }
    final digits = v >= 100 || i == 0 ? 0 : (v >= 10 ? 1 : 2);
    return '${v.toStringAsFixed(digits)} ${_units[i]}';
  }

  static String speed(int bytesPerSecond) => '${bytes(bytesPerSecond)}/s';

  static String clock(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  static String time(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  /// Latin digits to Persian digits.
  static String faDigits(String input) {
    const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    final out = StringBuffer();
    for (final unit in input.codeUnits) {
      if (unit >= 0x30 && unit <= 0x39) {
        out.write(fa[unit - 0x30]);
      } else {
        out.writeCharCode(unit);
      }
    }
    return out.toString();
  }
}
