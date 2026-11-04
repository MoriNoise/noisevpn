import 'package:flutter/material.dart';

import '../responsive/form_factor.dart';
import '../theme/app_tokens.dart';
import '../theme/app_type.dart';
import 'quick_toggles.dart';

/// Page title + subtitle + actions, like the panel's "Dashboard" header.
/// On desktop the header also carries language, appearance and theme.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
    this.expand = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  /// No scroll view: [child] gets all the height under the header, so a
  /// page can lay itself out to the window. The caller decides when the
  /// window is tall enough for that.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final desktop = context.formFactor.isDesktop;
    final pad = desktop ? 28.0 : 18.0;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final header = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppType.headline.copyWith(color: t.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppType.body.copyWith(color: t.textMuted)),
            ],
          ),
        ),
        for (final a in actions) ...[const SizedBox(width: 8), a],
        if (desktop) ...const [
          SizedBox(width: 16),
          LanguageToggle(),
          SizedBox(width: 8),
          AppearanceMenuButton(),
          SizedBox(width: 8),
          ThemeToggleButton(),
        ],
      ],
    );
    final gap = SizedBox(height: desktop ? 24 : 18);

    // Centered: on a maximised window the page sits in the middle instead
    // of hugging the sidebar with a dead strip on the far side.
    Widget frame(Widget column) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: SizedBox(width: double.infinity, child: column),
          ),
        );

    if (expand) {
      return Padding(
        padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + bottomInset),
        child: frame(Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [header, gap, Expanded(child: child)],
        )),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 8 + bottomInset),
      child: frame(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, gap, child],
      )),
    );
  }

  static const _maxWidth = 1180.0;
}

/// Icon-only or labelled header action (Refresh, Test ping).
class HeaderAction extends StatelessWidget {
  const HeaderAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final compact = !context.formFactor.isDesktop;
    final fg = primary ? t.onAccent : t.textPrimary;
    final radius = BorderRadius.circular(999);

    return Tooltip(
      message: label,
      child: Material(
        color: primary ? t.accent : (t.glassEnabled ? t.glass : t.surface),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: primary ? t.accent : (t.glassEnabled ? t.borderSoft : t.border)),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: busy ? null : onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 18,
                  child: busy
                      ? Padding(
                          padding: const EdgeInsets.all(2),
                          child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                        )
                      : Icon(icon, size: 18, color: fg),
                ),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Text(label, style: AppType.label.copyWith(color: fg, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered empty / error state with an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.actionIcon = Icons.refresh_rounded,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: t.accentSoft, shape: BoxShape.circle),
            child: Icon(icon, color: t.accent, size: 26),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: AppType.title.copyWith(color: t.textPrimary)),
          const SizedBox(height: 4),
          Text(body, textAlign: TextAlign.center, style: AppType.body.copyWith(color: t.textMuted)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: t.accent, textStyle: AppType.label),
              icon: Icon(actionIcon, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
