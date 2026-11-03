import 'package:flutter/painting.dart';

/// The same 12 accent swatches as the admin panel's appearance picker.
abstract final class AccentPalette {
  static const colors = <Color>[
    Color(0xFF8B5CF6), // violet (default)
    Color(0xFF6366F1), // indigo
    Color(0xFF3B82F6), // blue
    Color(0xFF06B6D4), // cyan
    Color(0xFF14B8A6), // teal
    Color(0xFF10B981), // emerald
    Color(0xFFF59E0B), // amber
    Color(0xFFF97316), // orange
    Color(0xFFF43F5E), // rose
    Color(0xFFEF4444), // red
    Color(0xFFEC4899), // pink
    Color(0xFF64748B), // slate
  ];

  static const defaultIndex = 0;
}
