import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_type.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/page_frame.dart';
import '../shell/shell_tab.dart';
import '../vpn/vpn_controller.dart';
import 'add_source_sheet.dart';
import 'countries.dart';
import 'server_models.dart';
import 'server_widgets.dart';
import 'servers_controller.dart';

class ServersScreen extends ConsumerWidget {
  const ServersScreen({super.key});

  void _select(BuildContext context, WidgetRef ref, String key) {
    ref.read(selectionProvider.notifier).select(key);
    final s = S.of(context);
    ref.read(vpnControllerProvider.notifier).reconnect(disconnectLabel: s.disconnect);
    if (context.formFactor == FormFactor.phone) {
      ref.read(shellTabProvider.notifier).go(ShellTabController.home);
    }
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref, SourceData source, String name) async {
    final s = S.of(context);
    final t = context.tokens;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: t.border)),
        title: Text(s.removeTitle(name), style: AppType.title.copyWith(color: t.textPrimary)),
        content: Text(s.removeSourceBody, style: AppType.body.copyWith(color: t.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: t.textSecondary),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: t.danger),
            child: Text(s.remove),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(serversControllerProvider.notifier).removeSource(source.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final data = ref.watch(serversControllerProvider);
    final pings = ref.watch(pingControllerProvider);
    final selection = ref.watch(selectionProvider);
    final servers = data.servers;
    final pinging = pings.values.any((p) => p.testing);
    final canPing = ref.watch(canPingProvider);
    final controller = ref.read(serversControllerProvider.notifier);
    final ping = ref.read(pingControllerProvider.notifier);

    final Widget body;
    if (data.isEmpty) {
      body = AppCard(
        child: EmptyState(
          icon: Icons.add_link_rounded,
          title: s.noServersTitle,
          body: s.noServersBody,
          actionLabel: s.addServers,
          actionIcon: Icons.add_rounded,
          onAction: () => showAddSourceSheet(context),
        ),
      );
    } else {
      final sections = <Widget>[
        _LocationTile(
          auto: true,
          title: s.fastestLocation,
          subtitle: s.fastestLocationHint,
          ping: bestPing(servers.map((e) => e.id), pings),
          selected: selection == SelectionController.auto,
          onTap: () => _select(context, ref, SelectionController.auto),
        ),
      ];

      for (final source in data.sources) {
        final name = source.isLocal ? s.localConfigs : source.name;
        sections.add(_SourceHeader(
          source: source,
          name: name,
          onRefresh: source.isLocal ? null : () => controller.refreshOne(source.id),
          onRemove: () => _confirmRemove(context, ref, source, name),
        ));
        // Every config is its own row, in subscription order.
        sections.add(_ServerGrid(
          children: [
            for (final server in source.servers)
              _LocationTile(
                code: server.countryCode,
                title: countryName(s, server.countryCode),
                subtitle: server.transport.toUpperCase(),
                tags: [if (server.tag != null) server.tag!],
                ping: pings[server.id],
                onPing: canPing ? () => ping.testOne(server) : null,
                selected: selection == SelectionController.keyFor(server),
                onTap: () => _select(context, ref, SelectionController.keyFor(server)),
                onRemove: source.isLocal ? () => controller.removeLocalServer(server) : null,
                removeLabel: s.removeConfig,
              ),
          ],
        ));
      }

      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: sections);
    }

    return PageFrame(
      title: s.navServers,
      subtitle: s.serversSubtitle,
      actions: [
        HeaderAction(
          icon: Icons.speed_rounded,
          label: s.testPing,
          busy: pinging,
          onPressed: servers.isEmpty || !canPing ? null : () => ping.testAll(servers),
        ),
        HeaderAction(
          icon: Icons.refresh_rounded,
          label: s.refresh,
          busy: data.refreshing,
          onPressed: data.sources.any((x) => !x.isLocal) ? controller.refreshAll : null,
        ),
        HeaderAction(
          icon: Icons.add_rounded,
          label: s.addServers,
          primary: true,
          onPressed: () => showAddSourceSheet(context),
        ),
      ],
      child: body,
    );
  }
}

/// One or two columns of rows depending on width.
class _ServerGrid extends StatelessWidget {
  const _ServerGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 720) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                children[i],
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < children.length; i += 2) ...[
              if (i > 0) const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: children[i]),
                  const SizedBox(width: 10),
                  Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox.shrink()),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Section title for a subscription or the local configs.
class _SourceHeader extends StatelessWidget {
  const _SourceHeader({required this.source, required this.name, required this.onRefresh, required this.onRemove});

  final SourceData source;
  final String name;
  final VoidCallback? onRefresh;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.tokens;

    final String detail;
    Color detailColor = t.textMuted;
    if (source.refreshing && source.servers.isEmpty) {
      detail = s.loadingServers;
    } else if (source.failed && source.servers.isEmpty) {
      detail = s.loadFailed;
      detailColor = t.danger;
    } else if (source.failed) {
      detail = s.refreshFailed;
      detailColor = t.warning;
    } else {
      final time = source.fetchedAt;
      detail = time == null
          ? s.serversCount(source.servers.length)
          : '${s.serversCount(source.servers.length)}    ${s.updatedAt(Fmt.time(time))}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 0, 6),
      child: Row(
        children: [
          Icon(source.isLocal ? Icons.description_outlined : Icons.link_rounded, size: 16, color: t.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.label.copyWith(color: t.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                Text(detail, style: AppType.caption.copyWith(color: detailColor, fontSize: 10.5)),
              ],
            ),
          ),
          if (onRefresh != null)
            source.refreshing
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: t.textMuted),
                    ),
                  )
                : IconButton(
                    tooltip: s.refresh,
                    onPressed: onRefresh,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.refresh_rounded, size: 18, color: t.textMuted),
                  ),
          IconButton(
            tooltip: s.remove,
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: t.textMuted),
          ),
        ],
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    this.code,
    this.auto = false,
    required this.title,
    this.subtitle,
    this.tags = const [],
    required this.ping,
    required this.selected,
    required this.onTap,
    this.onRemove,
    this.removeLabel,
    this.onPing,
  });

  final String? code;
  final bool auto;
  final String title;
  final String? subtitle;
  final List<String> tags;
  final PingResult? ping;
  final bool selected;
  final VoidCallback onTap;

  /// Local configs can be removed from their row.
  final VoidCallback? onRemove;
  final String? removeLabel;

  /// Pings just this server.
  final VoidCallback? onPing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(14);

    return Semantics(
      button: true,
      selected: selected,
      child: GlassSurface(
        radius: 14,
        borderColor: selected ? t.accentBorder : null,
        tint: selected ? t.accentFaint : null,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  auto ? const FlagTile.auto(size: 34) : FlagTile(code: code, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.label.copyWith(color: t.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                        if (subtitle != null || tags.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (subtitle != null)
                                Text(subtitle!, style: AppType.caption.copyWith(color: t.textMuted, fontSize: 10.5)),
                              for (final tag in tags) TagChip(label: tag),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PingBadge(result: ping, onTap: onPing),
                  if (onRemove != null)
                    IconButton(
                      tooltip: removeLabel,
                      onPressed: onRemove,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.delete_outline_rounded, size: 17, color: t.textMuted),
                    )
                  else
                    const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? t.accent : Colors.transparent,
                      border: Border.all(color: selected ? t.accent : t.borderStrong, width: 1.5),
                    ),
                    child: selected ? Icon(Icons.check_rounded, size: 12, color: t.onAccent) : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
