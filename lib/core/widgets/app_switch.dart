import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Pill switch in the accent colour.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged, this.label});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      toggled: value,
      label: label,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 46,
          height: 26,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? t.accent : t.surfaceHigh,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: value ? t.accent : t.borderStrong),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: value ? t.onAccent : t.textMuted,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
