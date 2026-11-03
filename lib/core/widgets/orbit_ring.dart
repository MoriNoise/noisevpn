import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'brand_mark.dart';

/// The brand mark inside a progress ring, a nod to the panel's donut chart.
/// The ring sweeps in once when [animation] runs from 0 to 1.
class OrbitRing extends StatelessWidget {
  const OrbitRing({
    super.key,
    required this.animation,
    this.size = 132,
    this.markSize = 56,
    this.fill = 0.74,
  });

  final Animation<double> animation;
  final double size;
  final double markSize;
  final double fill;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => CustomPaint(
        painter: _OrbitRingPainter(
          progress: Curves.easeOutCubic.transform(animation.value) * fill,
          accent: t.accent,
          track: t.border,
          strokeWidth: size * 0.055,
        ),
        child: child,
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(child: BrandMark(size: markSize)),
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  _OrbitRingPainter({
    required this.progress,
    required this.accent,
    required this.track,
    required this.strokeWidth,
  });

  final double progress;
  final Color accent;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth * 2.4) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = track,
    );
    if (progress <= 0.001) return;

    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          endAngle: sweep,
          colors: [accent.withValues(alpha: 0.15), accent],
          transform: const GradientRotation(start),
        ).createShader(rect),
    );

    final tip = Offset(
      center.dx + radius * math.cos(start + sweep),
      center.dy + radius * math.sin(start + sweep),
    );
    canvas.drawCircle(
      tip,
      strokeWidth * 1.3,
      Paint()
        ..color = accent.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(tip, strokeWidth * 0.42, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_OrbitRingPainter old) =>
      old.progress != progress || old.accent != accent || old.track != track;
}
