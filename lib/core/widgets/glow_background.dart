import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Soft accent glow behind full-screen pages, echoing the panel sidebar.
class GlowBackground extends StatelessWidget {
  const GlowBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: t.background)),
        PositionedDirectional(
          top: -220,
          start: -180,
          child: _Blob(size: 520, color: t.glow),
        ),
        PositionedDirectional(
          bottom: -260,
          end: -220,
          child: _Blob(size: 560, color: t.glow.withValues(alpha: t.glow.a * 0.45)),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
