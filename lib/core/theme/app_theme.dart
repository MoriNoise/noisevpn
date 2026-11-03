import 'package:flutter/material.dart';

import 'app_accent.dart';
import 'app_tokens.dart';

ThemeData buildAppTheme({
  required Brightness brightness,
  required AppAccent accent,
  required bool persian,
  required bool glass,
}) {
  final t = AppTokens.resolve(brightness: brightness, accent: accent, glass: glass);
  final scheme = ColorScheme.fromSeed(seedColor: accent.base, brightness: brightness).copyWith(
    primary: t.accent,
    onPrimary: t.onAccent,
    surface: t.surface,
    onSurface: t.textPrimary,
    error: t.danger,
    outline: t.border,
  );
  final family = persian ? 'Vazirmatn' : 'PlusJakartaSans';
  final fallback = persian ? const ['PlusJakartaSans'] : const ['Vazirmatn'];

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: t.background,
    fontFamily: family,
    fontFamilyFallback: fallback,
    splashFactory: InkRipple.splashFactory,
    hoverColor: t.textPrimary.withValues(alpha: 0.04),
    focusColor: t.accent.withValues(alpha: 0.18),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: t.accent,
      selectionColor: t.accent.withValues(alpha: 0.3),
      selectionHandleColor: t.accent,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: t.accent),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: t.surfaceRaised,
      contentTextStyle: TextStyle(color: t.textPrimary, fontFamily: family, fontSize: 13.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: t.border),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      textStyle: TextStyle(color: t.textPrimary, fontFamily: family, fontSize: 12),
    ),
    extensions: [t],
  );
}
