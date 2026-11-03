import 'package:flutter/material.dart';

/// Scales the desktop app so a fixed design canvas always fits the window.
///
/// Ported from the Palgam panel:
///
///   scale = (windowWidth / designWidth) * heightFactor
///   heightFactor = clamp(byHeight / byWidth, minHeightFactor, 1)
///
/// The width rule is absolute (the layout always gets at least
/// [designWidth] logical pixels), height only ever discounts the scale.
/// One addition for a client app: [maxScale] stops a maximised window on a
/// big monitor from blowing the UI up; the extra room becomes layout space.
///
/// Reads MediaQuery instead of using a LayoutBuilder on purpose, because it
/// sits above the Navigator (see the Palgam notes on overlay re-attachment).
class AppScaler extends StatelessWidget {
  const AppScaler({
    super.key,
    required this.child,
    this.designWidth = 1180,
    this.designHeight = 760,
    this.minHeightFactor = 0.8,
    this.maxScale = 1.25,
  });

  final Widget child;
  final double designWidth;
  final double designHeight;
  final double minHeightFactor;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final available = media.size;
    if (available.isEmpty || !available.width.isFinite || !available.height.isFinite) {
      return child;
    }

    final byWidth = available.width / designWidth;
    final byHeight = available.height / designHeight;
    final heightFactor = (byHeight / byWidth).clamp(minHeightFactor, 1.0);
    var scale = byWidth * heightFactor;
    if (scale > maxScale) scale = maxScale;
    if (scale <= 0 || !scale.isFinite) return child;

    final logical = Size(available.width / scale, available.height / scale);

    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox.fromSize(
        size: logical,
        child: MediaQuery(
          data: media.copyWith(
            size: logical,
            padding: media.padding / scale,
            viewPadding: media.viewPadding / scale,
            viewInsets: media.viewInsets / scale,
            systemGestureInsets: media.systemGestureInsets / scale,
          ),
          child: child,
        ),
      ),
    );
  }
}
