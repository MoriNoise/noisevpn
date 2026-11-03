import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../vpn/vpn_backend.dart';

/// The one big control on Home. The ring tells the state at a glance:
/// empty track when off, a travelling arc while connecting, a full glowing
/// ring once connected.
class ConnectButton extends StatefulWidget {
  const ConnectButton({
    super.key,
    required this.phase,
    required this.onPressed,
    required this.semanticLabel,
    this.enabled = true,
    this.size = 220,
  });

  /// False where the platform can't open a tunnel; the button is dimmed.
  final bool enabled;

  final VpnPhase phase;
  final VoidCallback onPressed;
  final String semanticLabel;
  final double size;

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton> with TickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  late final AnimationController _fill =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  bool _pressed = false;

  bool get _busy => widget.phase == VpnPhase.connecting || widget.phase == VpnPhase.disconnecting;

  @override
  void initState() {
    super.initState();
    if (widget.phase == VpnPhase.connected) _fill.value = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(ConnectButton old) {
    super.didUpdateWidget(old);
    if (old.phase != widget.phase) _sync();
  }

  void _sync() {
    if (!mounted) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (_busy && !reduce) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop();
    }
    final target = widget.phase == VpnPhase.connected ? 1.0 : 0.0;
    if (reduce) {
      _fill.value = target;
    } else {
      _fill.animateTo(target);
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final size = widget.size;
    final connected = widget.phase == VpnPhase.connected;
    final inner = size * 0.62;

    final innerDecoration = BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: connected
            ? [Color.lerp(t.success, Colors.white, 0.1)!, Color.lerp(t.success, Colors.black, 0.3)!]
            : _busy
                ? [t.accentSoft, t.accentFaint]
                : [t.surfaceHigh, t.surfaceRaised],
      ),
      border: Border.all(
        color: connected ? t.success.withValues(alpha: 0.6) : t.accentBorder,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: (connected ? t.success : t.accent).withValues(alpha: connected ? 0.45 : 0.22),
          blurRadius: connected ? 48 : 28,
          spreadRadius: connected ? 2 : 0,
        ),
      ],
    );

    final tappable = widget.enabled && widget.phase != VpnPhase.disconnecting;

    return Semantics(
      button: true,
      enabled: tappable,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: tappable ? (_) => setState(() => _pressed = true) : null,
        onTapUp: tappable ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: tappable ? () => setState(() => _pressed = false) : null,
        onTap: tappable ? widget.onPressed : null,
        child: MouseRegion(
          cursor: tappable ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: widget.enabled ? 1 : 0.45,
            child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 120),
            // The ring repaints every frame while connecting; isolate it so
            // the rest of the page (and the glow below) isn't repainted too.
            child: RepaintBoundary(
              child: AnimatedBuilder(
              animation: Listenable.merge([_spin, _fill]),
              builder: (context, child) => CustomPaint(
                painter: _RingPainter(
                  spin: _spin.value,
                  fill: Curves.easeOutCubic.transform(_fill.value),
                  busy: _busy,
                  accent: t.accent,
                  accentBright: t.accentBright,
                  success: t.success,
                  track: t.border,
                  strokeWidth: size * 0.035,
                ),
                child: child,
              ),
              child: RepaintBoundary(
                child: SizedBox.square(
                dimension: size,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    width: inner,
                    height: inner,
                    decoration: innerDecoration,
                    child: Icon(
                      Icons.power_settings_new_rounded,
                      size: inner * 0.38,
                      color: connected ? Colors.white : t.accent,
                    ),
                  ),
                ),
              ),
              ),
            ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.spin,
    required this.fill,
    required this.busy,
    required this.accent,
    required this.accentBright,
    required this.success,
    required this.track,
    required this.strokeWidth,
  });

  final double spin;
  final double fill;
  final bool busy;
  final Color accent;
  final Color accentBright;
  final Color success;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth * 3) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const top = -math.pi / 2;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = track);

    if (fill > 0.001) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 2.4
          ..color = success.withValues(alpha: 0.22 * fill)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawArc(
        rect,
        top,
        2 * math.pi * fill,
        false,
        stroke
          ..shader = SweepGradient(
            colors: [success.withValues(alpha: 0.55), success, success.withValues(alpha: 0.55)],
            transform: const GradientRotation(top),
          ).createShader(rect),
      );
    }

    if (busy) {
      const sweep = math.pi * 0.55;
      final start = top + 2 * math.pi * spin;
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
            colors: [accent.withValues(alpha: 0), accentBright],
            transform: GradientRotation(start),
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.spin != spin ||
      old.fill != fill ||
      old.busy != busy ||
      old.accent != accent ||
      old.success != success ||
      old.track != track;
}
