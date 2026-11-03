import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/app_type.dart';

/// Glass when the glass effect is on, a solid surface otherwise.
///
/// Deliberately no BackdropFilter: the only thing behind a card is the
/// static ambient colour field, which is already soft, so a real blur looks
/// the same while costing a full-screen offscreen pass per card per frame.
/// That is what made scrolling drop to ~30 fps on phones.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 18,
    this.padding = EdgeInsets.zero,
    this.borderColor,
    this.tint,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  /// Optional wash on top of the surface (selected rows, success states).
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final r = BorderRadius.circular(radius);
    final base = t.glassEnabled ? t.glass : t.surface;
    final fill = tint == null ? base : Color.alphaBlend(tint!, base);

    // A faint sheen from the top corner sells the glass without a blur.
    final sheen = Color.alphaBlend(Colors.white.withValues(alpha: t.isDark ? 0.045 : 0.35), fill);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.glassEnabled ? null : fill,
        gradient: t.glassEnabled
            ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [sheen, fill])
            : null,
        borderRadius: r,
        border: Border.all(color: borderColor ?? (t.glassEnabled ? t.borderSoft : t.border)),
      ),
      child: child,
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(padding: padding, borderColor: borderColor, tint: tint, child: child);
  }
}

/// Icon tile + title + optional subtitle, like the panel's card headers.
class CardHeader extends StatelessWidget {
  const CardHeader({super.key, required this.icon, required this.title, this.subtitle, this.trailing});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: t.accentSoft, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: t.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppType.title.copyWith(color: t.textPrimary)),
              if (subtitle != null)
                Text(subtitle!, style: AppType.caption.copyWith(color: t.textMuted)),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

/// Inline notice: info, warning or danger.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({super.key, required this.message, required this.icon, required this.color});

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: AppType.label.copyWith(color: t.textPrimary))),
          ],
        ),
      ),
    );
  }
}
