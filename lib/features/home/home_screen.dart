import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_type.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/page_frame.dart';
import '../servers/countries.dart';
import '../servers/server_models.dart';
import '../servers/server_widgets.dart';
import '../servers/servers_controller.dart';
import '../shell/shell_tab.dart';
import '../vpn/vpn_backend.dart';
import '../vpn/vpn_controller.dart';
import 'connect_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.tokens;
    // Only phase and server here: speeds and the timer change every second
    // and are watched by the small widgets that show them.
    final phase = ref.watch(vpnControllerProvider.select((v) => v.phase));
    final activeServer = ref.watch(vpnControllerProvider.select((v) => v.server));
    final resolved = ref.watch(resolvedServerProvider);
    final pings = ref.watch(pingControllerProvider);
    final auto = ref.watch(selectionProvider) == SelectionController.auto;
    final usage = ref.watch(serversControllerProvider.select((d) => d.usage));
    final supported = ref.watch(vpnBackendProvider).isSupported;

    // While a session is up, show the server it actually uses.
    final server = phase == VpnPhase.disconnected ? resolved : (activeServer ?? resolved);
    final wide = context.formFactor.isDesktop || MediaQuery.sizeOf(context).width >= 900;

    final hero = RepaintBoundary(child: _ConnectPanel(large: wide, supported: supported));
    final location = _LocationCard(
      server: server,
      auto: auto,
      ping: server == null ? null : pings[server.id],
    );
    final stats = RepaintBoundary(child: _StatsGrid(pingMs: server == null ? null : pings[server.id]?.ms));
    final plan = usage == null ? null : _PlanCard(usage: usage);

    return PageFrame(
      title: s.navHome,
      subtitle: s.homeSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!supported) ...[
            NoticeBanner(
              message: s.unsupportedPlatform(AppConfig.platformName),
              icon: Icons.info_outline_rounded,
              color: t.info,
            ),
            const SizedBox(height: 16),
          ],
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 11,
                  child: Column(children: [hero, const SizedBox(height: 16), location]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 9,
                  child: Column(
                    children: [
                      stats,
                      if (plan != null) ...[const SizedBox(height: 16), plan],
                    ],
                  ),
                ),
              ],
            )
          else ...[
            hero,
            const SizedBox(height: 12),
            location,
            const SizedBox(height: 12),
            stats,
            if (plan != null) ...[const SizedBox(height: 12), plan],
          ],
        ],
      ),
    );
  }
}

class _ConnectPanel extends ConsumerWidget {
  const _ConnectPanel({required this.large, required this.supported});

  final bool large;
  final bool supported;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.tokens;
    final vpn = ref.watch(vpnControllerProvider);

    final (title, color, hint) = switch (vpn.phase) {
      VpnPhase.connected => (s.statusConnected, t.success, s.hintTapDisconnect),
      VpnPhase.connecting => (s.statusConnecting, t.accent, s.hintTapCancel),
      VpnPhase.disconnecting => (s.statusDisconnecting, t.textMuted, ''),
      VpnPhase.disconnected => (
        s.statusDisconnected,
        t.textPrimary,
        supported ? s.hintTapConnect : s.notAvailableOn(AppConfig.platformName),
      ),
    };
    final failure = switch (vpn.failure) {
      VpnFailure.unsupported => s.notAvailableOn(AppConfig.platformName),
      VpnFailure.noServers => s.errNoServers,
      VpnFailure.permissionDenied => s.errPermission,
      VpnFailure.startFailed => s.errConnect,
      null => null,
    };
    final action = vpn.isActive ? s.disconnect : s.connect;

    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: large ? 36 : 28),
      child: Column(
        children: [
          if (failure != null) ...[
            NoticeBanner(message: failure, icon: Icons.error_outline_rounded, color: t.danger),
            const SizedBox(height: 20),
          ],
          ConnectButton(
            phase: vpn.phase,
            enabled: supported,
            size: large ? 236 : 206,
            semanticLabel: action,
            onPressed: () => ref.read(vpnControllerProvider.notifier).toggle(disconnectLabel: s.disconnect),
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              title,
              key: ValueKey(vpn.phase),
              style: AppType.headline.copyWith(color: color),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 26,
            child: vpn.phase == VpnPhase.connected
                ? Text(
                    s.n(Fmt.clock(vpn.duration)),
                    style: AppType.metric.copyWith(color: t.textSecondary, fontSize: 18),
                  )
                : Text(hint, style: AppType.body.copyWith(color: t.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends ConsumerWidget {
  const _LocationCard({required this.server, required this.auto, required this.ping});

  final VpnServer? server;
  final bool auto;
  final PingResult? ping;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.tokens;
    final srv = server;

    final title = srv == null ? s.fastestLocation : countryName(s, srv.countryCode);
    final subtitle = auto ? s.fastestLocation : (srv?.tag ?? srv?.transport.toUpperCase() ?? '');

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          srv == null ? const FlagTile.auto() : FlagTile(code: srv.countryCode),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.location, style: AppType.caption.copyWith(color: t.textFaint)),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.title.copyWith(color: t.textPrimary),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.caption.copyWith(color: t.textMuted),
                  ),
              ],
            ),
          ),
          PingBadge(result: ping),
          const SizedBox(width: 8),
          HeaderAction(
            icon: Icons.swap_horiz_rounded,
            label: s.change,
            onPressed: () => ref.read(shellTabProvider.notifier).go(ShellTabController.servers),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends ConsumerWidget {
  const _StatsGrid({required this.pingMs});

  final int? pingMs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpn = ref.watch(vpnControllerProvider);
    final s = S.of(context);
    final t = context.tokens;
    final ms = pingMs;
    final tiles = [
      _StatTile(icon: Icons.south_rounded, color: t.accent, label: s.downloadSpeed, value: s.n(Fmt.speed(vpn.downloadSpeed))),
      _StatTile(icon: Icons.north_rounded, color: t.info, label: s.uploadSpeed, value: s.n(Fmt.speed(vpn.uploadSpeed))),
      _StatTile(icon: Icons.swap_vert_rounded, color: t.warning, label: s.sessionData, value: s.n(Fmt.bytes(vpn.upload + vpn.download))),
      _StatTile(icon: Icons.speed_rounded, color: t.success, label: s.ping, value: ms == null ? '—' : s.ms(ms)),
    ];
    return Column(
      children: [
        Row(children: [Expanded(child: tiles[0]), const SizedBox(width: 12), Expanded(child: tiles[1])]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: tiles[2]), const SizedBox(width: 12), Expanded(child: tiles[3])]),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.color, required this.label, required this.value});

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.caption.copyWith(color: t.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value, style: AppType.metric.copyWith(color: t.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.usage});

  final SubscriptionUsage usage;

  String _expiry(S s) {
    final expire = usage.expire;
    if (expire == null) return s.planNoExpiry;
    final left = expire.difference(DateTime.now());
    if (left.isNegative) return s.planExpired;
    if (left.inHours < 24) return s.planExpiresToday;
    return s.planExpiresIn((left.inHours / 24).ceil());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.tokens;
    final used = s.n(Fmt.bytes(usage.used));
    final fraction = usage.fraction;
    final barColor = fraction >= 0.9 ? t.danger : (fraction >= 0.75 ? t.warning : t.accent);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(icon: Icons.data_usage_rounded, title: s.planTitle, subtitle: _expiry(s)),
          const SizedBox(height: 18),
          if (usage.unlimited)
            Text(s.planUnlimited(used), style: AppType.label.copyWith(color: t.textSecondary))
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 8,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: t.surfaceHigh)),
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: fraction,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [barColor, Color.lerp(barColor, Colors.white, 0.25)!]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.planUsed(used, s.n(Fmt.bytes(usage.total))),
                    style: AppType.label.copyWith(color: t.textSecondary),
                  ),
                ),
                Text(
                  s.n('${(fraction * 100).round()}%'),
                  style: AppType.label.copyWith(color: barColor, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
