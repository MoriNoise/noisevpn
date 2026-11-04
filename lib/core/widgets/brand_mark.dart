import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// The Noise logo (a ring around a rounded "N"), drawn as vectors so it
/// stays sharp at every size and follows the user's accent colour.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(t.accent, Colors.white, 0.25)!,
            t.accent,
            Color.lerp(t.accent, Colors.black, 0.35)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: t.accent.withValues(alpha: 0.45),
            blurRadius: size * 0.5,
            offset: Offset(0, size * 0.15),
          ),
        ],
      ),
      child: const CustomPaint(painter: _NoiseGlyphPainter(Colors.white)),
    );
  }
}

/// Proportions measured from assets/logo.png, relative to the ring radius.
class _NoiseGlyphPainter extends CustomPainter {
  const _NoiseGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.373; // outer ring radius
    final ringWidth = (r * 0.09).clamp(1.0, double.infinity);

    canvas.drawCircle(
      c,
      r - ringWidth / 2,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth,
    );

    final nx = r * 0.45;
    final ny = r * 0.477;
    final n = Path()
      ..moveTo(c.dx - nx, c.dy + ny)
      ..lineTo(c.dx - nx, c.dy - ny)
      ..lineTo(c.dx + nx, c.dy + ny)
      ..lineTo(c.dx + nx, c.dy - ny);

    canvas.drawPath(
      n,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.208
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_NoiseGlyphPainter old) => old.color != color;
}
