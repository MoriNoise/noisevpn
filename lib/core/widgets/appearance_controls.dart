import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../theme/app_tokens.dart';
import '../theme/app_type.dart';
import '../theme/appearance_controller.dart';
import '../theme/theme_transition.dart';
import 'accent_picker.dart';
import 'app_segmented.dart';
import 'app_switch.dart';

/// Mode, accent and glass: the same controls in Settings and in the
/// desktop appearance popover. Every change runs through [ThemeTransition].
class AppearanceControls extends ConsumerWidget {
  const AppearanceControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.tokens;
    final state = ref.watch(appearanceProvider);
    final controller = ref.read(appearanceProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSegmented<ThemeMode>(
          selected: state.mode,
          onChanged: (mode, origin) => ThemeTransition.run(() => controller.setMode(mode), origin: origin),
          options: [
            SegmentOption(value: ThemeMode.light, label: s.themeLight, icon: Icons.light_mode_outlined),
            SegmentOption(value: ThemeMode.dark, label: s.themeDark, icon: Icons.dark_mode_outlined),
            SegmentOption(value: ThemeMode.system, label: s.themeSystem, icon: Icons.brightness_auto_outlined),
          ],
        ),
        const SizedBox(height: 20),
        Text(s.accentColor, style: AppType.label.copyWith(color: t.textMuted)),
        const SizedBox(height: 10),
        AccentPicker(
          selected: state.accent,
          onSelected: (accent, origin) => ThemeTransition.run(() => controller.setAccent(accent), origin: origin),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.glassMode, style: AppType.label.copyWith(color: t.textPrimary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(s.glassModeHint, style: AppType.caption.copyWith(color: t.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Builder(
              builder: (context) => AppSwitch(
                value: state.glass,
                label: s.glassMode,
                onChanged: (v) => ThemeTransition.run(
                  () => controller.setGlass(v),
                  origin: ThemeTransition.originFrom(context),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
