import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Makes a theme, accent or language swap look like one movement.
///
/// Ported from the Palgam panel. Colours can't be tweened across a whole
/// tree, but pixels can: this takes a GPU snapshot of the app as it looks
/// now, lays it on top, lets the swap happen hidden underneath, then wipes
/// the snapshot away with a feathered circle growing from the control that
/// was tapped (or cross-fades when there is no origin).
///
/// If a snapshot can't be taken it falls back to an instant swap, so the
/// change itself always goes through.
class ThemeTransition extends StatefulWidget {
  const ThemeTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 520),
    this.curve = Curves.easeInOutCubic,
    this.enabled = true,
  });

  final Widget child;

  /// How long the old look takes to disappear.
  final Duration duration;

  final Curve curve;

  /// Set to `false` to fall back to an instant swap (respecting
  /// "reduce motion", for instance).
  final bool enabled;

  static _ThemeTransitionState? _host;

  /// True when a transition can actually be played right now.
  static bool get isAvailable {
    final host = _host;
    return host != null && host.mounted && host.widget.enabled;
  }

  /// Runs [apply] — the palette swap and everything it triggers — behind a
  /// snapshot of the current frame, then animates the snapshot away.
  ///
  /// [origin] is where the circular wipe starts, in the coordinate space of
  /// this widget; use [originFrom] to derive it from the tapped control.
  /// Without it the old look simply cross-fades.
  ///
  /// Always calls [apply] exactly once, transition or not.
  static void run(VoidCallback apply, {Offset? origin}) {
    final host = _host;
    if (host == null || !host.mounted || !host.widget.enabled) {
      apply();
      return;
    }
    host._play(apply, origin);
  }

  /// The centre of [context]'s widget, expressed in the transition's own
  /// coordinates — the natural starting point for the wipe when a button was
  /// pressed. Returns `null` when it cannot be resolved, which just means the
  /// transition cross-fades instead.
  static Offset? originFrom(BuildContext context) {
    final host = _host;
    if (host == null || !host.mounted) return null;

    final source = context.findRenderObject();
    final target = host._boundaryKey.currentContext?.findRenderObject();
    if (source is! RenderBox || target is! RenderBox) return null;
    if (!source.hasSize || !target.hasSize) return null;
    if (!source.attached || !target.attached) return null;

    try {
      final global = source.localToGlobal(source.size.center(Offset.zero));
      final local = target.globalToLocal(global);
      if (!local.dx.isFinite || !local.dy.isFinite) return null;
      return local;
    } catch (_) {
      return null;
    }
  }

  @override
  State<ThemeTransition> createState() => _ThemeTransitionState();
}

class _ThemeTransitionState extends State<ThemeTransition>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final CurvedAnimation _progress = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );

  /// Drives the plain cross-fade used when no origin is known.
  late final Animation<double> _fade = Tween<double>(begin: 1, end: 0).animate(
    _progress,
  );

  /// A wipe needs no global fade: the gradient band below already takes the
  /// still frame to nothing by the time it reaches the far corner, and fading
  /// the whole image on top of that would read as the panel dimming.
  static const Animation<double> _opaque = AlwaysStoppedAnimation<double>(1);

  ui.Image? _snapshot;
  Offset? _origin;

  @override
  void initState() {
    super.initState();
    ThemeTransition._host = this;
    _controller.addStatusListener(_onStatus);
  }

  @override
  void dispose() {
    if (identical(ThemeTransition._host, this)) ThemeTransition._host = null;
    _controller.removeStatusListener(_onStatus);
    _progress.dispose();
    _controller.dispose();
    _snapshot?.dispose();
    _snapshot = null;
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _dropSnapshot(rebuild: true);
  }

  void _dropSnapshot({required bool rebuild}) {
    final image = _snapshot;
    if (image == null) return;
    _snapshot = null;
    _origin = null;
    if (rebuild && mounted) setState(() {});

    // Freed a frame later, not now: the layer that is still on screen holds a
    // reference to this texture until it has been replaced by one that does
    // not.
    WidgetsBinding.instance.addPostFrameCallback((_) => image.dispose());
  }

  void _play(VoidCallback apply, Offset? origin) {
    // A second change landing mid-transition: drop the first snapshot rather
    // than stacking two stale images on top of each other.
    if (_controller.isAnimating) {
      _controller.stop();
      _dropSnapshot(rebuild: false);
    }

    final image = _capture();
    if (image == null) {
      apply();
      return;
    }

    _snapshot = image;
    _origin = origin;
    _controller.value = 0;

    // This `setState` and the rebuild that `apply` triggers land in the *same*
    // frame: the panel repaints in its new colours, and the snapshot covers it
    // completely, so none of that reaches the screen.
    setState(() {});
    apply();

    // Give the new look one fully painted frame — the expensive whole-tree
    // rebuild is in there — before anything of it is revealed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _snapshot == null) return;
      _controller.forward(from: 0);
    });
  }

  ui.Image? _capture() {
    try {
      final object = _boundaryKey.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) return null;
      if (!object.attached || !object.hasSize) return null;
      if (object.size.isEmpty) return null;

      // Capped: a 3x snapshot of a large desktop panel costs a lot of texture
      // memory for a difference nobody can see in a 420 ms wipe.
      final ratio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
      return object.toImageSync(pixelRatio: ratio.clamp(1.0, 2.0).toDouble());
    } catch (_) {
      // Renderers exist that cannot rasterise a layer synchronously. Not being
      // able to animate is not a reason to refuse the theme change.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _snapshot;
    final origin = _origin;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _boundaryKey, child: widget.child),
        if (image != null)
          Positioned.fill(
            // The old look is a picture, not a UI: it must never swallow a
            // tap, and it must never be read out.
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: origin == null
                    ? _stillFrame(image, _fade)
                    : AnimatedBuilder(
                        animation: _progress,
                        builder: (context, child) {
                          return ShaderMask(
                            // `dstIn` keeps the still frame only where the
                            // mask is opaque, so the gradient below is
                            // literally how much of the old look survives at
                            // each point.
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (rect) => _wipeShader(
                              rect,
                              origin,
                              _progress.value,
                            ),
                            child: child,
                          );
                        },
                        child: _stillFrame(image, _opaque),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  /// The wipe's edge.
  ///
  /// A hard circular clip was the first version of this, and it was wrong for
  /// a reason that only shows up on real content: the edge cuts *through*
  /// glyphs and icons. Half a letter in the old palette sitting against the
  /// other half in the new one does not read as a colour change — it reads as
  /// the letter having moved. The cure is to stop the boundary being a
  /// boundary: the old look now dissolves across a wide band, so at every
  /// point where a word is crossed, the two versions of it are blended rather
  /// than butted against each other.
  ///
  /// The band is sized from the viewport, so it stays proportionate on a small
  /// window and on a wide desktop panel alike.
  Shader _wipeShader(Rect rect, Offset origin, double fraction) {
    final reach = _maxRadius(rect.size, origin);
    final feather = math.max(rect.shortestSide * 0.3, 120.0);

    // The band travels far enough that its *trailing* edge — not its leading
    // one — clears the furthest corner by the end, otherwise the last sliver
    // of the old look would still be there at the final frame.
    final outer = (reach + feather) * fraction;
    final inner = outer - feather;

    // Nothing wiped yet: keep the still frame whole.
    if (outer <= 0) {
      return const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
      ).createShader(rect);
    }

    final knee = (inner / outer).clamp(0.0, 0.999);

    return RadialGradient(
      center: Alignment(
        (origin.dx / rect.width) * 2 - 1,
        (origin.dy / rect.height) * 2 - 1,
      ),
      radius: outer / rect.shortestSide,
      // Transparent where the new look has fully taken over, opaque where the
      // old one is untouched, and a long ramp in between.
      colors: const [
        Color(0x00FFFFFF),
        Color(0x00FFFFFF),
        Color(0xFFFFFFFF),
      ],
      stops: [0.0, knee, 1.0],
    ).createShader(rect);
  }

  /// Far enough to clear the furthest corner, whichever corner that is.
  double _maxRadius(Size size, Offset origin) {
    final dx = math.max(origin.dx, size.width - origin.dx);
    final dy = math.max(origin.dy, size.height - origin.dy);
    return math.sqrt(dx * dx + dy * dy);
  }

  Widget _stillFrame(ui.Image image, Animation<double> opacity) {
    // `RawImage.opacity` animates on the render object, so the fade costs a
    // repaint rather than a rebuild plus a full-screen `saveLayer`.
    return RawImage(
      image: image,
      fit: BoxFit.fill,
      opacity: opacity,
      filterQuality: FilterQuality.low,
      isAntiAlias: false,
    );
  }
}
