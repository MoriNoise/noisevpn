import 'package:flutter/painting.dart';

/// One selectable brand colour: five tones of one hue plus a stable id.
/// Everything else (tinted surfaces, washes, borders, glows) is derived
/// from these by [AppTokens], so adding a colour is a one-entry change.
/// Ported from the Palgam panel so both products share the same swatches.
class AppAccent {
  const AppAccent({
    required this.id,
    required this.base,
    required this.bright,
    required this.light,
    required this.deep,
    required this.dark,
  });

  /// Stable key written to storage. Never rename it.
  final String id;
  final Color base;
  final Color bright;
  final Color light;
  final Color deep;
  final Color dark;

  @override
  bool operator ==(Object other) => other is AppAccent && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

abstract final class AppAccents {
  static const violet = AppAccent(id: 'violet', base: Color(0xFF8B5CF6), bright: Color(0xFFA855F7), light: Color(0xFFC4B5FD), deep: Color(0xFF6D28D9), dark: Color(0xFF4C1D95));
  static const indigo = AppAccent(id: 'indigo', base: Color(0xFF6366F1), bright: Color(0xFF818CF8), light: Color(0xFFA5B4FC), deep: Color(0xFF4338CA), dark: Color(0xFF312E81));
  static const blue = AppAccent(id: 'blue', base: Color(0xFF3B82F6), bright: Color(0xFF60A5FA), light: Color(0xFF93C5FD), deep: Color(0xFF1D4ED8), dark: Color(0xFF1E3A8A));
  static const cyan = AppAccent(id: 'cyan', base: Color(0xFF06B6D4), bright: Color(0xFF22D3EE), light: Color(0xFF67E8F9), deep: Color(0xFF0E7490), dark: Color(0xFF164E63));
  static const teal = AppAccent(id: 'teal', base: Color(0xFF14B8A6), bright: Color(0xFF2DD4BF), light: Color(0xFF5EEAD4), deep: Color(0xFF0F766E), dark: Color(0xFF134E4A));
  static const emerald = AppAccent(id: 'emerald', base: Color(0xFF10B981), bright: Color(0xFF34D399), light: Color(0xFF6EE7B7), deep: Color(0xFF047857), dark: Color(0xFF064E3B));
  static const amber = AppAccent(id: 'amber', base: Color(0xFFF59E0B), bright: Color(0xFFFBBF24), light: Color(0xFFFCD34D), deep: Color(0xFFB45309), dark: Color(0xFF78350F));
  static const orange = AppAccent(id: 'orange', base: Color(0xFFF97316), bright: Color(0xFFFB923C), light: Color(0xFFFDBA74), deep: Color(0xFFC2410C), dark: Color(0xFF7C2D12));
  static const rose = AppAccent(id: 'rose', base: Color(0xFFF43F5E), bright: Color(0xFFFB7185), light: Color(0xFFFDA4AF), deep: Color(0xFFBE123C), dark: Color(0xFF881337));
  static const red = AppAccent(id: 'red', base: Color(0xFFEF4444), bright: Color(0xFFF87171), light: Color(0xFFFCA5A5), deep: Color(0xFFB91C1C), dark: Color(0xFF7F1D1D));
  static const pink = AppAccent(id: 'pink', base: Color(0xFFEC4899), bright: Color(0xFFF472B6), light: Color(0xFFF9A8D4), deep: Color(0xFFBE185D), dark: Color(0xFF831843));
  static const slate = AppAccent(id: 'slate', base: Color(0xFF64748B), bright: Color(0xFF94A3B8), light: Color(0xFFCBD5E1), deep: Color(0xFF334155), dark: Color(0xFF1E293B));

  static const all = <AppAccent>[violet, indigo, blue, cyan, teal, emerald, amber, orange, rose, red, pink, slate];

  static const fallback = violet;

  /// Unknown or missing ids fall back to violet instead of throwing.
  static AppAccent byId(String? id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return fallback;
  }
}
