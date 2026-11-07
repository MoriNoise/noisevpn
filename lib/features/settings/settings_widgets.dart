import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_type.dart';
import '../../core/widgets/app_switch.dart';

/// Two columns when there's room, one otherwise.
class SettingsColumns extends StatelessWidget {
  const SettingsColumns({super.key, required this.left, required this.right});

  final List<Widget> left;
  final List<Widget> right;

  List<Widget> _spaced(List<Widget> items) => [
        for (var i = 0; i < items.length; i++) ...[if (i > 0) const SizedBox(height: 12), items[i]],
      ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 760 || right.isEmpty || left.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _spaced([...left, ...right]),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _spaced(left))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _spaced(right))),
          ],
        );
      },
    );
  }
}

class SwitchRow extends StatelessWidget {
  const SwitchRow({super.key, required this.title, required this.hint, required this.value, required this.onChanged});

  final String title;
  final String? hint;
  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onChanged != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.label.copyWith(color: t.textPrimary, fontWeight: FontWeight.w700)),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(hint!, style: AppType.caption.copyWith(color: t.textMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          IgnorePointer(
            ignoring: !enabled,
            child: AppSwitch(value: value, label: title, onChanged: onChanged ?? (_) {}),
          ),
        ],
      ),
    );
  }
}

/// A label plus a wrap of choice chips, for options with more than three
/// values (a segmented control gets too narrow on phones).
class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.hint,
  });

  final String title;
  final String? hint;
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Opacity(
      opacity: onChanged == null ? 0.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppType.label.copyWith(color: t.textPrimary, fontWeight: FontWeight.w700)),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint!, style: AppType.caption.copyWith(color: t.textMuted)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (value, label) in options)
                _Chip(
                  label: label,
                  selected: value == selected,
                  onTap: onChanged == null ? null : () => onChanged!(value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(10);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? t.accent : t.surfaceRaised,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: selected ? t.accent : t.border),
            ),
            child: Text(
              label,
              style: AppType.label.copyWith(
                color: selected ? t.onAccent : t.textMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width outlined action button in the settings style.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key, required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: t.textPrimary,
        side: BorderSide(color: t.border),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppType.label,
      ),
      icon: Icon(icon, size: 18, color: t.accent),
      label: Text(label, textAlign: TextAlign.center),
    );
  }
}
