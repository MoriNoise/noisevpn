import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs.dart';
import 'app_accent.dart';

@immutable
class AppearanceState {
  const AppearanceState({required this.mode, required this.accent, required this.glass});

  final ThemeMode mode;
  final AppAccent accent;

  /// Frosted glass surfaces over the ambient colour field.
  final bool glass;

  AppearanceState copyWith({ThemeMode? mode, AppAccent? accent, bool? glass}) => AppearanceState(
        mode: mode ?? this.mode,
        accent: accent ?? this.accent,
        glass: glass ?? this.glass,
      );
}

/// Light/dark mode, brand colour and glass are three independent choices.
/// Wrap calls in `ThemeTransition.run` from the UI to animate them.
class AppearanceController extends Notifier<AppearanceState> {
  static const _modeKey = 'appearance.mode';
  static const _accentKey = 'appearance.accentId';
  static const _legacyAccentKey = 'appearance.accent';
  static const _glassKey = 'appearance.glass';

  @override
  AppearanceState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedMode = prefs.getString(_modeKey);
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == savedMode,
      orElse: () => ThemeMode.dark,
    );

    var accent = AppAccents.byId(prefs.getString(_accentKey));
    // Step 1 stored the swatch as an index.
    final legacy = prefs.getInt(_legacyAccentKey);
    if (prefs.getString(_accentKey) == null && legacy != null && legacy >= 0 && legacy < AppAccents.all.length) {
      accent = AppAccents.all[legacy];
    }

    return AppearanceState(
      mode: mode,
      accent: accent,
      glass: prefs.getBool(_glassKey) ?? true,
    );
  }

  void setMode(ThemeMode mode) {
    if (mode == state.mode) return;
    state = state.copyWith(mode: mode);
    ref.read(sharedPreferencesProvider).setString(_modeKey, mode.name);
  }

  void setAccent(AppAccent accent) {
    if (accent == state.accent) return;
    state = state.copyWith(accent: accent);
    ref.read(sharedPreferencesProvider).setString(_accentKey, accent.id);
  }

  void setGlass(bool glass) {
    if (glass == state.glass) return;
    state = state.copyWith(glass: glass);
    ref.read(sharedPreferencesProvider).setBool(_glassKey, glass);
  }
}

final appearanceProvider =
    NotifierProvider<AppearanceController, AppearanceState>(AppearanceController.new);
