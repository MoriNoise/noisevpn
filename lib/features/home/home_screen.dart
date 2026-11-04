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
    final sources = ref.watch(serversControllerProvider).sources;
    final supported = ref.watch(vpnBackendProvider).isSupported;

    // While a session is up, show the server it actually uses.
    final server = phase == VpnPhase.disconnected ? resolved : (activeServer ?? resolved);

    // The plan belongs to the subscription of the server in use, so with
    // several subscriptions it follows the selection. Local configs and
    // subscriptions that don't report usage have no plan card.
    SourceData? planSource;
    for (final src in sources) {
      if (server != null && src.id == server.sourceId && src.usage != null) planSource = src;
    }

    final wide = context.formFactor.isDesktop || MediaQuery.sizeOf(context).width >= 900;
    final notice = supported
        ? null
        : NoticeBanner(
            message: s.unsupportedPlatform(AppConfig.platformName),
            icon: Icons.info_outline_rounded,
            color: t.info,
          );
    final location = _LocationCard(
      server: server,
      auto: auto,
      ping: server == null ? null : pings[server.id],
    );
    final pingMs = server == null ? null : pings[server.id]?.ms;

    if (!wide) {
      return LayoutBuilder(
        builder: (context, c) {
          final plan = planSource == null ? null : _PlanCard(source: planSource, compact: true);
          // Very short screens (landscape phones) still get a scroll view.
          if (c.maxHeight < (plan == null ? 540 : 620)) {
            return PageFrame(
              title: s.navHome,
              subtitle: s.homeSubtitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (notice != null) ...[notice, const SizedBox(height: 12)],
                  SizedBox(height: 330, child: _ConnectPanel(supported: supported)),
                  const SizedBox(height: 10),
                  location,
                  const SizedBox(height: 10),
                  RepaintBoundary(child: _StatsStrip(pingMs: pingMs)),
                  if (plan != null) ...[const SizedBox(height: 10), plan],
                ],
              ),
            );
          }
          // Everything on one screen: the connect panel takes what's left.
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.navHome, style: AppType.headline.copyWith(color: t.textPrimary)),
                const SizedBox(height: 10),
                if (notice != null) ...[notice, const SizedBox(height: 10)],
                Expanded(child: RepaintBoundary(child: _ConnectPanel(supported: supported))),
                const SizedBox(height: 10),
                location,
                const SizedBox(height: 10),
                RepaintBoundary(child: _StatsStrip(pingMs: pingMs)),
                if (plan != null) ...[const SizedBox(height: 10), plan],
              ],
            ),
          );
        },
      );
    }

    final plan = planSource == null ? null : _PlanCard(source: planSource, compact: false);
    return PageFrame(
      title: s.navHome,
      subtitle: s.homeSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (notice != null) ...[notice, const SizedBox(height: 16)],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 11,
                child: Column(
                  children: [
                    SizedBox(height: 400, child: RepaintBoundary(child: _ConnectPanel(supported: supported))),
                    const SizedBox(height: 16),
                    location,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 9,
                child: Column(
                  children: [
                    RepaintBoundary(child: _StatsGrid(pingMs: pingMs)),
                    if (plan != null) ...[const SizedBox(height: 16), plan],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Connect button, status and timer. Sizes the button to the height it is
/// given, so on phones the whole Home fits without scrolling.
class _ConnectPanel extends ConsumerWidget {
  const _ConnectPanel({required this.supported});

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
      VpnFailure.timeout => s.errTimeout,
      null => null,
    };
    final action = vpn.isActive ? s.disconnect : s.connect;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: LayoutBuilder(
        builder: (context, c) {
          // Room for status, hint and (when shown) the error banner.
          final reserved = 78.0 + (failure != null ? 64 : 0);
          final size = (c.maxHeight - reserved).clamp(120.0, 236.0).toDouble();
          final finalSize = size > c.maxWidth * 0.8 ? c.maxWidth * 0.8 : size;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (failure != null) ...[
                NoticeBanner(message: failure, icon: Icons.error_outline_rounded, color: t.danger),
                const SizedBox(height: 12),
              ],
              ConnectButton(
                phase: vpn.phase,
                enabled: supported,
                size: finalSize,
                semanticLabel: action,
                onPressed: () => ref.read(vpnControllerProvider.notifier).toggle(disconnectLabel: s.disconnect),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  title,
                  key: ValueKey(vpn.phase),
                  style: AppType.headline.copyWith(color: color, fontSize: 20),
                ),
              ),
              SizedBox(
                height: 24,
                child: vpn.phase == VpnPhase.connected
                    ? Text(
                        s.n(Fmt.clock(vpn.duration)),
                        style: AppType.metric.copyWith(color: t.textSecondary, fontSize: 17),
                      )
                    : Text(hint, style: AppType.body.copyWith(color: t.textMuted)),
              ),
            ],
          );
        },
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          PingBadge(
            result: ping,
            onTap: srv != null && ref.watch(canPingProvider)
                ? () => ref.read(pingControllerProvider.notifier).testOne(srv)
                : null,
          ),
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

/// The four live numbers in one row, for phones.
class _StatsStrip extends ConsumerWidget {
  const _StatsStrip({required this.pingMs});

  final int? pingMs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpn = ref.watch(vpnControllerProvider);
    final s = S.of(context);
    final t = context.tokens;
    final ms = pingMs;
    final items = [
      (Icons.south_rounded, t.accent, s.downloadSpeed, s.n(Fmt.speed(vpn.downloadSpeed))),
      (Icons.north_rounded, t.info, s.uploadSpeed, s.n(Fmt.speed(vpn.uploadSpeed))),
      (Icons.swap_vert_rounded, t.warning, s.sessionData, s.n(Fmt.bytes(vpn.upload + vpn.download))),
      (Icons.speed_rounded, t.success, s.ping, ms == null ? '—' : s.ms(ms)),
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          for (final (icon, color, label, value) in items)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value, style: AppType.metric.copyWith(color: t.textPrimary, fontSize: 14)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.caption.copyWith(color: t.textMuted, fontSize: 10.5),
                  ),
                ],
              ),
            ),
        ],
      ),
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

/// Remaining data and days of the subscription the current server is from.
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.source, required this.compact});

  final SourceData source;
  final bool compact;

  String _expiry(S s, SubscriptionUsage usage) {
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
    final usage = source.usage!;
    final used = s.n(Fmt.bytes(usage.used));
    final fraction = usage.fraction;
    final barColor = fraction >= 0.9 ? t.danger : (fraction >= 0.75 ? t.warning : t.accent);
    final expired = usage.expire != null && usage.expire!.isBefore(DateTime.now());

    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: compact ? 6 : 8,
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
    );
    final usageText = usage.unlimited ? s.planUnlimited(used) : s.planUsed(used, s.n(Fmt.bytes(usage.total)));
    final expiry = Text(
      _expiry(s, usage),
      style: AppType.caption.copyWith(color: expired ? t.danger : t.textMuted, fontWeight: FontWeight.w600),
    );

    if (compact) {
      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.data_usage_rounded, size: 16, color: t.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    source.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.label.copyWith(color: t.textPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
                expiry,
              ],
            ),
            const SizedBox(height: 8),
            if (!usage.unlimited) ...[bar, const SizedBox(height: 6)],
            Text(usageText, style: AppType.caption.copyWith(color: t.textSecondary)),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(icon: Icons.data_usage_rounded, title: s.planTitle, subtitle: source.name, trailing: expiry),
          const SizedBox(height: 18),
          if (!usage.unlimited) ...[bar, const SizedBox(height: 10)],
          Row(
            children: [
              Expanded(child: Text(usageText, style: AppType.label.copyWith(color: t.textSecondary))),
              if (!usage.unlimited)
                Text(
                  s.n('${(fraction * 100).round()}%'),
                  style: AppType.label.copyWith(color: barColor, fontWeight: FontWeight.w800),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
