import 'package:flutter/material.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_type.dart';
import 'flag_images.dart';
import 'servers_controller.dart';

/// Country flag in a rounded tile. Windows can't draw flag emoji, so it
/// shows the country code there instead.
class FlagTile extends StatelessWidget {
  const FlagTile({super.key, required this.code, this.size = 42}) : auto = false;

  const FlagTile.auto({super.key, this.size = 42})
      : code = null,
        auto = true;

  final String? code;
  final bool auto;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(size * 0.3);

    if (auto) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.accentBright, t.accentDeep],
          ),
        ),
        child: Icon(Icons.bolt_rounded, color: Colors.white, size: size * 0.55),
      );
    }

    // Flag images instead of emoji: Windows has no flag emoji, and the
    // emoji look different on every other platform.
    final c = code;
    final png = c == null ? null : flagPng(c);
    final Widget inner;
    if (png != null) {
      inner = Container(
        width: size * 0.74,
        height: size * 0.52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.1),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          png,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          excludeFromSemantics: true,
        ),
      );
    } else if (c != null) {
      inner = Text(c, style: AppType.label.copyWith(color: t.textSecondary, fontWeight: FontWeight.w800));
    } else {
      inner = Icon(Icons.public_rounded, size: size * 0.5, color: t.textMuted);
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        borderRadius: radius,
        border: Border.all(color: t.border),
      ),
      child: inner,
    );
  }
}

/// Ping pill: green under 150 ms, amber under 300 ms, red above.
/// With [onTap] it pings that one server: tap the pill to re-test, or the
/// speed icon when it has never been tested.
class PingBadge extends StatelessWidget {
  const PingBadge({super.key, required this.result, this.onTap});

  final PingResult? result;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = _badge(context);
    final tap = onTap;
    if (tap == null) return badge ?? const SizedBox.shrink();
    final busy = result?.testing ?? false;
    return Tooltip(
      message: S.of(context).testPing,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: busy ? null : tap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: badge ?? Icon(Icons.speed_rounded, size: 19, color: context.tokens.textMuted),
        ),
      ),
    );
  }

  Widget? _badge(BuildContext context) {
    final t = context.tokens;
    final s = S.of(context);
    final r = result;
    if (r == null) return null;

    if (r.ms == null && r.testing) {
      return SizedBox.square(
        dimension: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: t.textMuted),
      );
    }

    final ms = r.ms;
    final color = ms == null
        ? t.textFaint
        : (ms < 150 ? t.success : (ms < 300 ? t.warning : t.danger));
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: r.testing ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              ms == null ? s.pingTimeout : s.ms(ms),
              style: AppType.caption.copyWith(color: ms == null ? t.textMuted : color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small grey chip for remark tags ("direct", "AI Ready").
class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.border),
      ),
      child: Text(label, style: AppType.caption.copyWith(color: t.textSecondary, fontWeight: FontWeight.w600, fontSize: 10)),
    );
  }
}

/// Best result across a set of servers, for a country row.
PingResult? bestPing(Iterable<String> ids, Map<String, PingResult> pings) {
  PingResult? best;
  var anyTesting = false;
  var anyResult = false;
  for (final id in ids) {
    final p = pings[id];
    if (p == null) continue;
    anyResult = true;
    if (p.testing) anyTesting = true;
    final ms = p.ms;
    if (ms != null && (best?.ms == null || ms < best!.ms!)) best = p;
  }
  if (!anyResult) return null;
  return PingResult(ms: best?.ms, testing: anyTesting);
}
