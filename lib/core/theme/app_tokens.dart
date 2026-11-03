import 'package:flutter/material.dart';

import 'app_accent.dart';

/// Every colour the app paints, resolved for one (brightness, accent, glass)
/// combination. Read with `context.tokens`.
///
/// The derivation follows the Palgam palette: neutrals keep a breath of the
/// brand hue so the whole app reads as one coloured object, and every wash,
/// border and glow is computed from the accent's five tones.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.brightness,
    required this.glassEnabled,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceHigh,
    required this.glass,
    required this.border,
    required this.borderStrong,
    required this.borderSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.onAccent,
    required this.shadow,
    required this.accent,
    required this.accentBright,
    required this.accentLight,
    required this.accentDeep,
    required this.accentDark,
    required this.accentSoft,
    required this.accentFaint,
    required this.accentBorder,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.glow,
    required this.railTop,
    required this.railBottom,
  });

  final Brightness brightness;

  /// Frosted, blurred surfaces over the ambient colour field.
  final bool glassEnabled;

  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceHigh;

  /// Translucent surface used when [glassEnabled] is on.
  final Color glass;

  final Color border;
  final Color borderStrong;

  /// Hairline highlight for glass edges.
  final Color borderSoft;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;
  final Color onAccent;
  final Color shadow;

  final Color accent;
  final Color accentBright;
  final Color accentLight;
  final Color accentDeep;
  final Color accentDark;
  final Color accentSoft;
  final Color accentFaint;
  final Color accentBorder;

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;

  final Color glow;
  final Color railTop;
  final Color railBottom;

  bool get isDark => brightness == Brightness.dark;

  static Color _tint(Color hue, Color over, double amount) =>
      Color.alphaBlend(hue.withValues(alpha: amount), over);

  /// Amber and cyan are bright enough that white text on them fails.
  static Color _onAccent(Color c) =>
      c.computeLuminance() > 0.55 ? const Color(0xFF14131A) : Colors.white;

  factory AppTokens.resolve({
    required Brightness brightness,
    required AppAccent accent,
    required bool glass,
  }) {
    return brightness == Brightness.dark
        ? AppTokens._dark(accent, glass)
        : AppTokens._light(accent, glass);
  }

  factory AppTokens._dark(AppAccent a, bool glass) {
    final surface = _tint(a.base, const Color(0xFF13131B), 0.022);
    const success = Color(0xFF4ADE80);
    const warning = Color(0xFFF59E0B);
    const danger = Color(0xFFF05252);
    return AppTokens(
      brightness: Brightness.dark,
      glassEnabled: glass,
      background: _tint(a.base, const Color(0xFF08080C), 0.012),
      backgroundAlt: _tint(a.base, const Color(0xFF0C0C13), 0.018),
      surface: surface,
      surfaceRaised: _tint(a.base, const Color(0xFF1A1A24), 0.026),
      surfaceHigh: _tint(a.base, const Color(0xFF22222F), 0.03),
      glass: _tint(a.base, const Color(0xFF15151F), 0.05).withValues(alpha: 0.58),
      border: _tint(a.base, const Color(0xFF262633), 0.05),
      borderStrong: _tint(a.base, const Color(0xFF383848), 0.06),
      borderSoft: const Color(0x17FFFFFF),
      textPrimary: const Color(0xFFF3F3F8),
      textSecondary: const Color(0xFFB4B4CC),
      textMuted: const Color(0xFF8B8BA6),
      textFaint: const Color(0xFF5C5C73),
      onAccent: _onAccent(a.base),
      shadow: const Color(0x80000000),
      accent: a.base,
      accentBright: a.bright,
      accentLight: a.light,
      accentDeep: a.deep,
      accentDark: a.dark,
      accentSoft: a.base.withValues(alpha: 0.15),
      accentFaint: a.base.withValues(alpha: 0.08),
      accentBorder: a.base.withValues(alpha: 0.35),
      success: success,
      successSoft: success.withValues(alpha: 0.14),
      warning: warning,
      warningSoft: warning.withValues(alpha: 0.14),
      danger: danger,
      dangerSoft: danger.withValues(alpha: 0.12),
      info: const Color(0xFF38BDF8),
      glow: a.base.withValues(alpha: 0.32),
      railTop: _tint(a.dark, const Color(0xFF12121C), 0.55),
      railBottom: _tint(a.base, const Color(0xFF0A0A12), 0.02),
    );
  }

  factory AppTokens._light(AppAccent a, bool glass) {
    const success = Color(0xFF16A34A);
    const warning = Color(0xFFD97706);
    const danger = Color(0xFFDC2626);
    return AppTokens(
      brightness: Brightness.light,
      glassEnabled: glass,
      background: _tint(a.base, const Color(0xFFF5F6FA), 0.02),
      backgroundAlt: _tint(a.base, const Color(0xFFEDEFF6), 0.03),
      surface: Colors.white,
      surfaceRaised: _tint(a.base, const Color(0xFFF4F5F9), 0.015),
      surfaceHigh: _tint(a.base, const Color(0xFFE9EBF2), 0.03),
      glass: Colors.white.withValues(alpha: 0.62),
      border: _tint(a.base, const Color(0xFFE3E6EF), 0.05),
      borderStrong: _tint(a.base, const Color(0xFFCBD0DF), 0.07),
      borderSoft: const Color(0x99FFFFFF),
      textPrimary: const Color(0xFF12131C),
      textSecondary: const Color(0xFF4B5169),
      textMuted: const Color(0xFF5E657D),
      textFaint: const Color(0xFF9AA0B4),
      onAccent: _onAccent(a.base),
      shadow: const Color(0x1F1B1F3B),
      accent: a.base,
      accentBright: a.deep,
      accentLight: a.bright,
      accentDeep: a.deep,
      accentDark: a.dark,
      accentSoft: a.base.withValues(alpha: 0.14),
      accentFaint: a.base.withValues(alpha: 0.07),
      accentBorder: a.base.withValues(alpha: 0.32),
      success: success,
      successSoft: success.withValues(alpha: 0.12),
      warning: warning,
      warningSoft: warning.withValues(alpha: 0.12),
      danger: danger,
      dangerSoft: danger.withValues(alpha: 0.10),
      info: const Color(0xFF0284C7),
      glow: a.base.withValues(alpha: 0.20),
      railTop: _tint(a.base, Colors.white, 0.12),
      railBottom: Colors.white,
    );
  }

  @override
  AppTokens copyWith({bool? glassEnabled}) => AppTokens(
        brightness: brightness,
        glassEnabled: glassEnabled ?? this.glassEnabled,
        background: background,
        backgroundAlt: backgroundAlt,
        surface: surface,
        surfaceRaised: surfaceRaised,
        surfaceHigh: surfaceHigh,
        glass: glass,
        border: border,
        borderStrong: borderStrong,
        borderSoft: borderSoft,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textMuted: textMuted,
        textFaint: textFaint,
        onAccent: onAccent,
        shadow: shadow,
        accent: accent,
        accentBright: accentBright,
        accentLight: accentLight,
        accentDeep: accentDeep,
        accentDark: accentDark,
        accentSoft: accentSoft,
        accentFaint: accentFaint,
        accentBorder: accentBorder,
        success: success,
        successSoft: successSoft,
        warning: warning,
        warningSoft: warningSoft,
        danger: danger,
        dangerSoft: dangerSoft,
        info: info,
        glow: glow,
        railTop: railTop,
        railBottom: railBottom,
      );

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      glassEnabled: t < 0.5 ? glassEnabled : other.glassEnabled,
      background: l(background, other.background),
      backgroundAlt: l(backgroundAlt, other.backgroundAlt),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      glass: l(glass, other.glass),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      borderSoft: l(borderSoft, other.borderSoft),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      textFaint: l(textFaint, other.textFaint),
      onAccent: l(onAccent, other.onAccent),
      shadow: l(shadow, other.shadow),
      accent: l(accent, other.accent),
      accentBright: l(accentBright, other.accentBright),
      accentLight: l(accentLight, other.accentLight),
      accentDeep: l(accentDeep, other.accentDeep),
      accentDark: l(accentDark, other.accentDark),
      accentSoft: l(accentSoft, other.accentSoft),
      accentFaint: l(accentFaint, other.accentFaint),
      accentBorder: l(accentBorder, other.accentBorder),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      info: l(info, other.info),
      glow: l(glow, other.glow),
      railTop: l(railTop, other.railTop),
      railBottom: l(railBottom, other.railBottom),
    );
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
