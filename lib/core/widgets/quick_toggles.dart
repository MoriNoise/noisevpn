import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/locale_controller.dart';
import '../l10n/strings.dart';
import '../theme/app_tokens.dart';
import '../theme/app_type.dart';
import '../theme/appearance_controller.dart';
import '../theme/theme_transition.dart';
import 'appearance_controls.dart';

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final void Function(BuildContext context) onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: t.glassEnabled ? t.glass : t.surface,
        shape: CircleBorder(side: BorderSide(color: t.glassEnabled ? t.borderSoft : t.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => onTap(context),
          child: SizedBox.square(dimension: 38, child: Icon(icon, size: 18, color: t.textPrimary)),
        ),
      ),
    );
  }
}

/// Sun/moon flip. The new look wipes outward from the button.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _RoundButton(
      icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
      tooltip: S.of(context).changeTheme,
      onTap: (ctx) => ThemeTransition.run(
        () => ref.read(appearanceProvider.notifier).setMode(isDark ? ThemeMode.light : ThemeMode.dark),
        origin: ThemeTransition.originFrom(ctx),
      ),
    );
  }
}

/// Palette button that opens mode, accent and glass under it.
class AppearanceMenuButton extends StatelessWidget {
  const AppearanceMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = S.of(context);
    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(t.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(t.shadow),
        elevation: const WidgetStatePropertyAll(16),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(16)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: t.border)),
        ),
      ),
      menuChildren: [
        SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.appearance, style: AppType.title.copyWith(color: t.textPrimary)),
              const SizedBox(height: 14),
              const AppearanceControls(),
            ],
          ),
        ),
      ],
      builder: (context, controller, _) => _RoundButton(
        icon: Icons.palette_outlined,
        tooltip: s.appearance,
        onTap: (_) => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// Compact FA / EN switch. Cross-fades between the two languages.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  static const _options = [('fa', 'فا'), ('en', 'EN')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final current = ref.watch(localeProvider).languageCode;
    return Semantics(
      label: S.of(context).language,
      child: Container(
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: t.glassEnabled ? t.glass : t.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: t.glassEnabled ? t.borderSoft : t.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (code, label) in _options)
              _Pill(
                label: label,
                selected: code == current,
                onTap: () {
                  if (code == current) return;
                  ThemeTransition.run(() => ref.read(localeProvider.notifier).set(Locale(code)));
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(999);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: selected ? t.accent : Colors.transparent, borderRadius: radius),
          child: Text(
            label,
            style: AppType.label.copyWith(
              color: selected ? t.onAccent : t.textMuted,
              fontWeight: FontWeight.w700,
              // Pin the face so "فا" never falls back to a font without Persian.
              fontFamily: 'Vazirmatn',
            ),
          ),
        ),
      ),
    );
  }
}
