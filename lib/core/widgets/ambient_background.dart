import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// The colour field behind every screen: soft orbs in the accent's tones.
/// Glass surfaces blur this, which is what gives them their tint.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [t.backgroundAlt, t.background],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(child: CustomPaint(painter: _OrbPainter(t))),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter(this.t);

  final AppTokens t;

  @override
  void paint(Canvas canvas, Size size) {
    final strength = (t.isDark ? 1.0 : 0.7) * (t.glassEnabled ? 1.0 : 0.6);
    final side = size.shortestSide;
    void orb(Offset center, double radius, Color color, double alpha) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: alpha * strength), color.withValues(alpha: 0)],
          ).createShader(rect),
      );
    }

    orb(Offset(size.width * 0.08, size.height * 0.02), side * 0.75, t.accent, 0.34);
    orb(Offset(size.width * 0.95, size.height * 0.38), side * 0.6, t.accentDeep, 0.26);
    orb(Offset(size.width * 0.35, size.height * 1.02), side * 0.65, t.accentBright, 0.18);
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.t.accent != t.accent || old.t.isDark != t.isDark || old.t.glassEnabled != t.glassEnabled;
}
