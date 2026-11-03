import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/app_type.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onPressed != null && !loading;
    final radius = BorderRadius.circular(14);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: onPressed == null && !loading ? 0.5 : 1,
      child: Semantics(
        button: true,
        enabled: enabled,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: Ink(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                colors: [t.accent, Color.lerp(t.accent, Colors.white, 0.14)!],
              ),
              boxShadow: [
                BoxShadow(
                  color: t.accent.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onPressed : null,
              child: Center(
                child: loading
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: t.onAccent),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: t.onAccent),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: AppType.body.copyWith(
                              color: t.onAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined button in the danger color, used for sign out.
class DangerOutlineButton extends StatelessWidget {
  const DangerOutlineButton({super.key, required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(12);
    return Material(
      color: t.danger.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: t.danger.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: t.danger),
              const SizedBox(width: 8),
              Text(label, style: AppType.label.copyWith(color: t.danger, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
