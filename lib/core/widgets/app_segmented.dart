import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_transition.dart';
import '../theme/app_type.dart';

/// [origin] is the tapped segment's centre, for [ThemeTransition]'s wipe.
typedef SegmentChanged<T> = void Function(T value, Offset? origin);

class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Segmented control matching the panel's Light / Dark / System picker.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final SegmentChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: _Segment<T>(
                option: o,
                selected: o.value == selected,
                onChanged: onChanged,
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({required this.option, required this.selected, required this.onChanged});

  final SegmentOption<T> option;
  final bool selected;
  final SegmentChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = selected ? t.onAccent : t.textMuted;
    final radius = BorderRadius.circular(10);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () => onChanged(option.value, ThemeTransition.originFrom(context)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(vertical: option.icon == null ? 10 : 12, horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? t.accent : Colors.transparent,
              borderRadius: radius,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: t.accent.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (option.icon != null) ...[
                  Icon(option.icon, size: 18, color: fg),
                  const SizedBox(height: 6),
                ],
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.label.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
