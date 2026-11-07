import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_type.dart';
import '../../core/widgets/app_card.dart';
import '../servers/add_source_sheet.dart';
import '../servers/countries.dart';
import '../servers/server_models.dart';
import '../servers/server_widgets.dart';
import '../servers/servers_controller.dart';
import '../shell/shell_tab.dart';
import '../vpn/vpn_controller.dart';

/// Desktop Home's right column: pick (or switch) a location without leaving
/// Home. Adding, editing and removing subscriptions stays on Servers.
class ServerPanel extends ConsumerStatefulWidget {
  const ServerPanel({super.key});

  @override
  ConsumerState<ServerPanel> createState() => _ServerPanelState();
}

class _ServerPanelState extends ConsumerState<ServerPanel> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _select(String key) {
    ref.read(selectionProvider.notifier).select(key);
    // Connected: switch to it right away. Disconnected: just selects it.
    ref.read(vpnControllerProvider.notifier).reconnect(disconnectLabel: S.of(context).disconnect);
  }

  bool _matches(S s, VpnServer server) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return serverTitle(s, server).toLowerCase().contains(q) ||
        countryName(s, server.countryCode).toLowerCase().contains(q) ||
        server.remark.toLowerCase().contains(q) ||
        server.transport.toLowerCase().contains(q) ||
        server.protocol.toLowerCase().contains(q) ||
        (server.tag?.toLowerCase().contains(q) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.tokens;
    final data = ref.watch(serversControllerProvider);
    final pings = ref.watch(pingControllerProvider);
    final selection = ref.watch(selectionProvider);
    final canPing = ref.watch(canPingProvider);
    final pinging = pings.values.any((p) => p.testing);
    final servers = data.servers;
    final ping = ref.read(pingControllerProvider.notifier);

    final rows = <Widget>[];
    if (servers.isNotEmpty && _query.trim().isEmpty) {
      rows.add(_Row(
        flag: const FlagTile.auto(size: 32),
        title: s.fastestLocation,
        subtitle: s.fastestLocationHint,
        ping: bestPing(servers.map((e) => e.id), pings),
        selected: selection == SelectionController.auto,
        onTap: () => _select(SelectionController.auto),
      ));
    }
    for (final source in data.sources) {
      final visible = [for (final x in source.servers) if (_matches(s, x)) x];
      if (visible.isEmpty) continue;
      rows.add(_GroupHeader(
        name: source.isLocal ? s.localConfigs : source.name,
        count: s.serversCount(visible.length),
        refreshing: source.refreshing,
      ));
      for (final server in visible) {
        rows.add(_Row(
          flag: FlagTile(code: server.countryCode, size: 32),
          title: serverTitle(s, server),
          subtitle: serverSubtitle(s, server),
          ping: pings[server.id],
          onPing: canPing ? () => ping.testOne(server) : null,
          selected: selection == SelectionController.keyFor(server),
          onTap: () => _select(SelectionController.keyFor(server)),
        ));
      }
    }

    final Widget list;
    if (data.isEmpty) {
      list = _Empty(
        icon: Icons.add_link_rounded,
        text: s.noServersBody,
        action: s.addServers,
        onAction: () => showAddSourceSheet(context),
      );
    } else if (rows.isEmpty) {
      list = _Empty(icon: Icons.search_off_rounded, text: s.noMatches);
    } else {
      list = ListView.builder(
        padding: const EdgeInsets.only(bottom: 4),
        itemCount: rows.length,
        itemBuilder: (_, i) => rows[i],
      );
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    style: AppType.label.copyWith(color: t.textPrimary),
                    decoration: InputDecoration(
                      hintText: s.searchLocations,
                      hintStyle: AppType.label.copyWith(color: t.textFaint),
                      prefixIcon: Icon(Icons.search_rounded, size: 19, color: t.textMuted),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: s.cancel,
                              icon: Icon(Icons.close_rounded, size: 17, color: t.textMuted),
                              onPressed: () => setState(() {
                                _search.clear();
                                _query = '';
                              }),
                            ),
                      isDense: true,
                      filled: true,
                      fillColor: t.surfaceRaised,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.border)),
                      enabledBorder:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.border)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: t.accentBorder, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: servers.isEmpty || !canPing || pinging ? null : () => ping.testAll(servers),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.textPrimary,
                    side: BorderSide(color: t.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: AppType.label,
                  ),
                  icon: pinging
                      ? SizedBox.square(dimension: 15, child: CircularProgressIndicator(strokeWidth: 2, color: t.accent))
                      : Icon(Icons.speed_rounded, size: 18, color: t.accent),
                  label: Text(s.testPing),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: list),
          Divider(height: 1, color: t.border),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => ref.read(shellTabProvider.notifier).go(ShellTabController.servers),
              style: TextButton.styleFrom(foregroundColor: t.textMuted, textStyle: AppType.caption),
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: Text(s.manageServers),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.name, required this.count, required this.refreshing});

  final String name;
  final String count;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.caption.copyWith(color: t.textMuted, fontWeight: FontWeight.w700),
            ),
          ),
          if (refreshing) ...[
            SizedBox.square(dimension: 11, child: CircularProgressIndicator(strokeWidth: 1.6, color: t.textMuted)),
            const SizedBox(width: 6),
          ],
          Text(count, style: AppType.caption.copyWith(color: t.textFaint)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.ping,
    required this.selected,
    required this.onTap,
    this.onPing,
  });

  final Widget flag;
  final String title;
  final String subtitle;
  final PingResult? ping;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onPing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(12);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: radius,
                color: selected ? t.accentFaint : null,
                border: Border.all(color: selected ? t.accentBorder : Colors.transparent),
              ),
              child: Row(
                children: [
                  flag,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.label.copyWith(
                            color: t.textPrimary,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.caption.copyWith(color: t.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PingBadge(result: ping, onTap: onPing),
                  if (selected) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.check_circle_rounded, size: 18, color: t.accent),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text, this.action, this.onAction});

  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: t.textFaint),
            const SizedBox(height: 10),
            Text(text, textAlign: TextAlign.center, style: AppType.label.copyWith(color: t.textMuted)),
            if (action != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onAction,
                style: FilledButton.styleFrom(backgroundColor: t.accent, foregroundColor: t.onAccent),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(action!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
