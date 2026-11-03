import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../core/config/app_config.dart';
import '../../core/l10n/strings.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_type.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/brand_mark.dart';
import '../auth/auth_repository.dart';
import '../home/home_screen.dart';
import '../servers/countries.dart';
import '../servers/servers_screen.dart';
import '../settings/settings_screen.dart';
import '../vpn/vpn_backend.dart';
import '../vpn/vpn_controller.dart';
import 'shell_tab.dart';

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final index = ref.watch(shellTabProvider);
    final factor = context.formFactor;
    final sidebar = factor.isDesktop || (factor == FormFactor.tablet && MediaQuery.sizeOf(context).width >= 900);

    final items = [
      _NavItem(Icons.home_outlined, Icons.home_rounded, s.navHome),
      _NavItem(Icons.public, Icons.public_rounded, s.navServers),
      _NavItem(Icons.settings_outlined, Icons.settings_rounded, s.navSettings),
    ];
    void select(int i) => ref.read(shellTabProvider.notifier).go(i);

    final body = IndexedStack(
      index: index,
      children: [
        const HomeScreen(),
        const ServersScreen(),
        SettingsScreen(user: user),
      ],
    );

    if (sidebar) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AmbientBackground(
          child: Row(
            children: [
              _Sidebar(items: items, index: index, onSelect: select, user: user),
              Expanded(child: SafeArea(child: body)),
            ],
          ),
        ),
      );
    }

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(bottom: false, child: body),
        bottomNavigationBar: _BottomBar(items: items, index: index, onSelect: select),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.items, required this.index, required this.onSelect, required this.user});

  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onSelect;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = S.of(context);
    final alpha = t.glassEnabled ? 0.72 : 1.0;

    final panel = RepaintBoundary(
      child: Container(
      width: 248,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            t.railTop.withValues(alpha: alpha),
            Color.lerp(t.railTop, t.railBottom, 0.6)!.withValues(alpha: alpha),
            t.railBottom.withValues(alpha: alpha),
          ],
          stops: const [0, 0.45, 1],
        ),
        border: BorderDirectional(end: BorderSide(color: t.glassEnabled ? t.borderSoft : t.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const BrandMark(size: 34),
                  const SizedBox(width: 10),
                  Text(AppInfo.name, style: AppType.title.copyWith(color: t.textPrimary, fontSize: 17)),
                ],
              ),
              const SizedBox(height: 28),
              if (AppConfig.requireLogin) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: t.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.glassEnabled ? t.borderSoft : t.border),
                ),
                child: Row(
                  children: [
                    UserAvatar(user: user, size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.signedInAs, style: AppType.caption.copyWith(color: t.textFaint)),
                          Text(
                            user.username,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.label.copyWith(color: t.textPrimary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ],
              for (var i = 0; i < items.length; i++) ...[
                _SideNavItem(item: items[i], selected: i == index, onTap: () => onSelect(i)),
                const SizedBox(height: 4),
              ],
              const Spacer(),
              const _StatusCard(),
            ],
          ),
        ),
      ),
    ),
    );

    return panel;
  }
}

/// Live connection state at the bottom of the sidebar.
class _StatusCard extends ConsumerWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final s = S.of(context);
    final vpn = ref.watch(vpnControllerProvider);

    final (label, color) = switch (vpn.phase) {
      VpnPhase.connected => (s.statusConnected, t.success),
      VpnPhase.connecting => (s.statusConnecting, t.accent),
      VpnPhase.disconnecting => (s.statusDisconnecting, t.warning),
      VpnPhase.disconnected => (s.statusDisconnected, t.textFaint),
    };
    final detail = vpn.phase == VpnPhase.disconnected || vpn.server == null
        ? s.version(AppInfo.version)
        : countryName(s, vpn.server!.countryCode);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: vpn.phase == VpnPhase.connected ? t.successSoft : t.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: vpn.phase == VpnPhase.connected
              ? t.success.withValues(alpha: 0.35)
              : (t.glassEnabled ? t.borderSoft : t.border),
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: vpn.phase == VpnPhase.connected
                  ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppType.label.copyWith(color: t.textPrimary, fontWeight: FontWeight.w700)),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.caption.copyWith(color: t.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({required this.item, required this.selected, required this.onTap});

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = selected ? t.onAccent : t.textMuted;
    final radius = BorderRadius.circular(12);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: selected ? LinearGradient(colors: [t.accent, t.accentBright]) : null,
              boxShadow: selected
                  ? [BoxShadow(color: t.accent.withValues(alpha: 0.32), blurRadius: 16, offset: const Offset(0, 6))]
                  : null,
            ),
            child: Row(
              children: [
                Icon(selected ? item.selectedIcon : item.icon, size: 19, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppType.label.copyWith(color: fg, fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: t.onAccent.withValues(alpha: 0.8), shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.items, required this.index, required this.onSelect});

  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bar = Container(
      decoration: BoxDecoration(
        color: t.glassEnabled ? t.glass : t.surface,
        border: Border(top: BorderSide(color: t.glassEnabled ? t.borderSoft : t.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(child: _BottomItem(item: items[i], selected: i == index, onTap: () => onSelect(i))),
            ],
          ),
        ),
      ),
    );
    return bar;
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({required this.item, required this.selected, required this.onTap});

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = selected ? t.accent : t.textMuted;
    final radius = BorderRadius.circular(14);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: selected ? t.accentSoft : Colors.transparent, borderRadius: radius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? item.selectedIcon : item.icon, size: 22, color: fg),
              const SizedBox(height: 4),
              Text(item.label, style: AppType.caption.copyWith(color: fg, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Initial-letter avatar on the accent gradient.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 40});

  final AuthUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.accentBright, t.accentDeep],
        ),
      ),
      child: Text(
        user.initial,
        style: AppType.label.copyWith(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.w800, height: 1),
      ),
    );
  }
}
