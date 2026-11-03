import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_accent.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_transition.dart';

class AccentPicker extends StatelessWidget {
  const AccentPicker({super.key, required this.selected, required this.onSelected});

  final AppAccent selected;

  /// [origin] is the tapped swatch's centre, for the colour wipe.
  final void Function(AppAccent accent, Offset? origin) onSelected;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < AppAccents.all.length; i++)
          _Swatch(
            accent: AppAccents.all[i],
            selected: AppAccents.all[i] == selected,
            label: s.accentSwatch(i + 1),
            onSelected: onSelected,
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.accent, required this.selected, required this.label, required this.onSelected});

  final AppAccent accent;
  final bool selected;
  final String label;
  final void Function(AppAccent accent, Offset? origin) onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onSelected(accent, ThemeTransition.originFrom(context)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 38,
          height: 38,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: selected ? t.textPrimary : Colors.transparent, width: 2),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.4),
                radius: 0.95,
                colors: [accent.light, accent.base, accent.deep],
                stops: const [0, 0.55, 1],
              ),
            ),
            child: selected
                ? const Center(child: Icon(Icons.check_rounded, size: 17, color: Colors.white))
                : null,
          ),
        ),
      ),
    );
  }
}
