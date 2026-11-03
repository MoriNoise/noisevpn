import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

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
      child: Icon(Icons.graphic_eq_rounded, color: Colors.white, size: size * 0.58),
    );
  }
}
