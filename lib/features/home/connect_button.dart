import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// Radar waves and orbiting dots while connecting.
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  /// Shockwave, particles and the button's pop the moment it connects.
  late final AnimationController _burst =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
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
    if (old.phase != widget.phase) {
      final justConnected = widget.phase == VpnPhase.connected && old.phase == VpnPhase.connecting;
      _sync();
      if (justConnected && !MediaQuery.disableAnimationsOf(context)) {
        _burst.forward(from: 0);
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _sync() {
    if (!mounted) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (_busy && !reduce) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop();
    }
    if (widget.phase == VpnPhase.connecting && !reduce) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else if (_pulse.isAnimating || _pulse.value != 0) {
      _pulse
        ..stop()
        ..value = 0;
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
    _pulse.dispose();
    _burst.dispose();
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
              animation: Listenable.merge([_pulse, _burst]),
              builder: (context, child) {
                final fx = _FxPainter(
                  pulse: _pulse.value,
                  connecting: widget.phase == VpnPhase.connecting,
                  burst: _burst.isAnimating ? _burst.value : 0,
                  accent: t.accent,
                  accentBright: t.accentBright,
                  success: t.success,
                  innerRadius: inner / 2,
                  ringRadius: (size - size * 0.035 * 3) / 2,
                );
                // Breathes while connecting; pops when it connects.
                final b = _burst.isAnimating ? _burst.value : 0.0;
                final pop = b < 0.35 ? math.sin(b / 0.35 * math.pi) * 0.1 : 0.0;
                final breath = widget.phase == VpnPhase.connecting ? math.sin(_pulse.value * 2 * math.pi) * 0.025 : 0.0;
                return CustomPaint(
                  painter: fx.back(),
                  foregroundPainter: fx.front(),
                  child: Transform.scale(scale: 1 + pop + breath, child: child),
                );
              },
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


/// Connect effects around the button. [back] draws under it (radar waves,
/// orbiting dots), [front] over it (the shockwave and particles when the
/// session comes up, which travel out past the ring).
class _FxPainter {
  _FxPainter({
    required this.pulse,
    required this.connecting,
    required this.burst,
    required this.accent,
    required this.accentBright,
    required this.success,
    required this.innerRadius,
    required this.ringRadius,
  });

  final double pulse;
  final bool connecting;
  final double burst;
  final Color accent;
  final Color accentBright;
  final Color success;
  final double innerRadius;
  final double ringRadius;

  CustomPainter back() => _Paint(this, front: false);
  CustomPainter front() => _Paint(this, front: true);

  void paintBack(Canvas canvas, Offset c) {
    if (!connecting) return;
    // Three radar waves from the button out to the ring.
    for (var i = 0; i < 3; i++) {
      final p = (pulse + i / 3) % 1.0;
      final r = innerRadius + (ringRadius - innerRadius) * Curves.easeOut.transform(p);
      final a = math.pow(1 - p, 1.6).toDouble() * 0.5;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 + 2.4 * (1 - p)
          ..color = accent.withValues(alpha: a),
      );
    }
    // Two glowing dots orbiting between the button and the ring.
    final orbit = (innerRadius + ringRadius) / 2;
    for (var i = 0; i < 2; i++) {
      final angle = -pulse * 2 * math.pi * 1.5 + i * math.pi;
      final pos = c + Offset(math.cos(angle), math.sin(angle)) * orbit;
      for (var k = 0; k < 6; k++) {
        // A short comet tail behind each dot.
        final back = angle + k * 0.09;
        final tail = c + Offset(math.cos(back), math.sin(back)) * orbit;
        canvas.drawCircle(tail, 3.2 - k * 0.4, Paint()..color = accentBright.withValues(alpha: 0.5 * (1 - k / 6)));
      }
      canvas.drawCircle(
        pos,
        7,
        Paint()
          ..color = accentBright.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(pos, 3.6, Paint()..color = Colors.white.withValues(alpha: 0.95));
    }
  }

  void paintFront(Canvas canvas, Offset c) {
    if (burst <= 0 || burst >= 1) return;
    // Two shockwaves, the second a beat later.
    for (final delay in const [0.0, 0.14]) {
      final b = ((burst - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (b <= 0 || b >= 1) continue;
      final r = innerRadius + (ringRadius * 1.32 - innerRadius) * Curves.easeOutCubic.transform(b);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10 * (1 - b) + 1
          ..color = success.withValues(alpha: 0.55 * (1 - b)),
      );
    }
    // A brief flash on the button.
    if (burst < 0.3) {
      canvas.drawCircle(
        c,
        innerRadius * 1.05,
        Paint()
          ..color = success.withValues(alpha: 0.35 * (1 - burst / 0.3))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
    // Particles flying out past the ring.
    const count = 18;
    final light = Color.lerp(success, Colors.white, 0.45)!;
    final travel = Curves.easeOutCubic.transform(burst);
    for (var i = 0; i < count; i++) {
      final jitter = ((i * 37) % 11) / 11 - 0.5;
      final angle = i / count * 2 * math.pi + jitter * 0.3;
      final reach = ringRadius * (1.08 + 0.22 * ((i * 53) % 7) / 7);
      final r = innerRadius + (reach - innerRadius) * travel;
      final pos = c + Offset(math.cos(angle), math.sin(angle)) * r;
      final fade = (1 - burst).clamp(0.0, 1.0);
      canvas.drawCircle(
        pos,
        (i.isEven ? 3.4 : 2.4) * (0.4 + 0.6 * fade),
        Paint()..color = (i.isEven ? success : light).withValues(alpha: fade),
      );
    }
  }
}

class _Paint extends CustomPainter {
  _Paint(this.fx, {required this.front});

  final _FxPainter fx;
  final bool front;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (front) {
      fx.paintFront(canvas, c);
    } else {
      fx.paintBack(canvas, c);
    }
  }

  @override
  bool shouldRepaint(_Paint old) =>
      old.fx.pulse != fx.pulse ||
      old.fx.burst != fx.burst ||
      old.fx.connecting != fx.connecting ||
      old.fx.accent != fx.accent ||
      old.fx.success != fx.success;
}
