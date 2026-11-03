import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_type.dart';
import 'countries.dart';
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

  static bool get _emojiFlags => kIsWeb || defaultTargetPlatform != TargetPlatform.windows;

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

    final c = code;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        borderRadius: radius,
        border: Border.all(color: t.border),
      ),
      child: c != null && _emojiFlags
          ? Text(flagEmoji(c), style: TextStyle(fontSize: size * 0.5, height: 1.1))
          : Text(
              c ?? '?',
              style: AppType.label.copyWith(color: t.textSecondary, fontWeight: FontWeight.w800),
            ),
    );
  }
}

/// Ping pill: green under 150 ms, amber under 300 ms, red above.
class PingBadge extends StatelessWidget {
  const PingBadge({super.key, required this.result});

  final PingResult? result;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = S.of(context);
    final r = result;
    if (r == null) return const SizedBox.shrink();

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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.border),
      ),
      child: Text(label, style: AppType.caption.copyWith(color: t.textSecondary, fontWeight: FontWeight.w600)),
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
