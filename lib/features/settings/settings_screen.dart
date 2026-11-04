import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../core/config/app_config.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_type.dart';
import '../../core/theme/theme_transition.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_segmented.dart';
import '../../core/widgets/app_switch.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/appearance_controls.dart';
import '../../core/widgets/page_frame.dart';
import '../../core/widgets/primary_button.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import '../shell/app_shell.dart' show UserAvatar;
import '../vpn/vpn_controller.dart';
import '../vpn/vpn_settings.dart';
import 'app_picker_page.dart';

enum _Tab { appearance, connection, general }

bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
bool get _windows => !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.user});

  final AuthUser user;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _Tab _tab = _Tab.appearance;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final Widget body = switch (_tab) {
      _Tab.appearance => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardHeader(icon: Icons.palette_outlined, title: s.appearance, subtitle: s.appearanceSubtitle),
              const SizedBox(height: 18),
              const AppearanceControls(),
            ],
          ),
        ),
      _Tab.connection => const _ConnectionTab(),
      _Tab.general => _GeneralTab(user: widget.user),
    };

    return PageFrame(
      title: s.navSettings,
      subtitle: s.settingsSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AppSegmented<_Tab>(
                selected: _tab,
                onChanged: (tab, _) => setState(() => _tab = tab),
                options: [
                  SegmentOption(value: _Tab.appearance, label: s.appearance, icon: Icons.palette_outlined),
                  SegmentOption(value: _Tab.connection, label: s.tabConnection, icon: Icons.vpn_lock_outlined),
                  SegmentOption(value: _Tab.general, label: s.tabGeneral, icon: Icons.tune_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(key: ValueKey(_tab), child: body),
          ),
        ],
      ),
    );
  }
}

/// Two columns when there's room, one otherwise.
class _Columns extends StatelessWidget {
  const _Columns({required this.left, required this.right});

  final List<Widget> left;
  final List<Widget> right;

  List<Widget> _spaced(List<Widget> items) => [
        for (var i = 0; i < items.length; i++) ...[if (i > 0) const SizedBox(height: 12), items[i]],
      ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 760 || right.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _spaced([...left, ...right]),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _spaced(left))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _spaced(right))),
          ],
        );
      },
    );
  }
}

// ── Connection ────────────────────────────────────────────────────────────

class _ConnectionTab extends ConsumerWidget {
  const _ConnectionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.tokens;
    final active = ref.watch(vpnControllerProvider.select((v) => v.isActive));
    final settings = ref.watch(vpnSettingsProvider);

    final notice = active
        ? AppCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: t.info),
                const SizedBox(width: 10),
                Expanded(child: Text(s.applyOnReconnect, style: AppType.label.copyWith(color: t.textPrimary))),
                const SizedBox(width: 10),
                HeaderAction(
                  icon: Icons.refresh_rounded,
                  label: s.reconnectNow,
                  primary: true,
                  onPressed: () => ref.read(vpnControllerProvider.notifier).restart(disconnectLabel: s.disconnect),
                ),
              ],
            ),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (notice != null) ...[notice, const SizedBox(height: 12)],
        _Columns(
          left: const [_ModeCard()],
          right: [
            if (_android) const _PerAppCard(),
            // Windows takes bypassSubnets too (as direct rules inside Xray).
            if ((_android || _windows) && !settings.proxyOnly) const _NetworkCard(),
          ],
        ),
      ],
    );
  }
}

class _ModeCard extends ConsumerWidget {
  const _ModeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.tokens;
    final settings = ref.watch(vpnSettingsProvider);
    final controller = ref.read(vpnSettingsProvider.notifier);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(icon: Icons.vpn_lock_outlined, title: s.connectionMode, subtitle: s.connectionModeHint),
          const SizedBox(height: 16),
          AppSegmented<bool>(
            selected: settings.proxyOnly,
            onChanged: (proxy, _) => controller.update((v) => v.copyWith(proxyOnly: proxy)),
            options: [
              SegmentOption(value: false, label: s.modeTun, icon: Icons.shield_outlined),
              SegmentOption(value: true, label: s.modeProxy, icon: Icons.lan_outlined),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            settings.proxyOnly
                ? (_windows ? s.modeProxyHintWindows(settings.socksPort) : s.modeProxyHint(settings.socksPort))
                : (_windows ? s.modeTunHintWindows : s.modeTunHint),
            style: AppType.caption.copyWith(color: t.textMuted),
          ),
          if (settings.proxyOnly) ...[
            const SizedBox(height: 16),
            _PortField(port: settings.socksPort),
          ],
        ],
      ),
    );
  }
}

class _PortField extends ConsumerStatefulWidget {
  const _PortField({required this.port});

  final int port;

  @override
  ConsumerState<_PortField> createState() => _PortFieldState();
}

class _PortFieldState extends ConsumerState<_PortField> {
  late final _controller = TextEditingController(text: '${widget.port}');
  final _focus = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _save();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() {
    final port = int.tryParse(_controller.text.trim());
    if (port == null || port < 1024 || port > 65535) {
      setState(() => _error = S.of(context).errPort);
      return;
    }
    setState(() => _error = null);
    ref.read(vpnSettingsProvider.notifier).update((v) => v.copyWith(socksPort: port));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AppTextField(
                label: s.socksPort,
                controller: _controller,
                focusNode: _focus,
                icon: Icons.numbers_rounded,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '127.0.0.1:${widget.port}',
              onPressed: () => Clipboard.setData(ClipboardData(text: '127.0.0.1:${widget.port}')),
              icon: Icon(Icons.copy_rounded, size: 19, color: t.textMuted),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!, style: AppType.caption.copyWith(color: t.danger)),
        ],
      ],
    );
  }
}

class _PerAppCard extends ConsumerWidget {
  const _PerAppCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.tokens;
    final settings = ref.watch(vpnSettingsProvider);
    final controller = ref.read(vpnSettingsProvider.notifier);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(icon: Icons.apps_rounded, title: s.perApp, subtitle: s.perAppHint),
          const SizedBox(height: 16),
          if (settings.proxyOnly)
            NoticeBanner(message: s.perAppProxyNote, icon: Icons.info_outline_rounded, color: t.info)
          else ...[
            AppSegmented<PerAppMode>(
              selected: settings.perAppMode,
              onChanged: (mode, _) => controller.update((v) => v.copyWith(perAppMode: mode)),
              options: [
                SegmentOption(value: PerAppMode.off, label: s.perAppOff),
                SegmentOption(value: PerAppMode.bypass, label: s.perAppBypass),
                SegmentOption(value: PerAppMode.only, label: s.perAppOnly),
              ],
            ),
            if (settings.perAppMode != PerAppMode.off) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AppPickerPage()),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: t.textPrimary,
                  side: BorderSide(color: t.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: AppType.label,
                ),
                icon: Icon(Icons.checklist_rounded, size: 18, color: t.accent),
                label: Text(s.chooseApps(settings.selectedApps.length)),
              ),
              if (settings.perAppMode == PerAppMode.only) ...[
                const SizedBox(height: 10),
                Text(s.perAppOnlyNote, style: AppType.caption.copyWith(color: t.textMuted)),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _NetworkCard extends ConsumerWidget {
  const _NetworkCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final settings = ref.watch(vpnSettingsProvider);
    final controller = ref.read(vpnSettingsProvider.notifier);

    return AppCard(
      child: Column(
        children: [
          _SwitchRow(
            title: s.bypassLan,
            hint: s.bypassLanHint,
            value: settings.bypassLan,
            onChanged: (v) => controller.update((x) => x.copyWith(bypassLan: v)),
          ),
          // Windows always sends DNS through the proxy; the switch is Android's.
          if (_android) ...[
            const SizedBox(height: 16),
            _SwitchRow(
              title: s.dnsTunnel,
              hint: s.dnsTunnelHint,
              value: settings.dnsThroughTunnel,
              onChanged: (v) => controller.update((x) => x.copyWith(dnsThroughTunnel: v)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.hint, required this.value, required this.onChanged});

  final String title;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppType.label.copyWith(color: t.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(hint, style: AppType.caption.copyWith(color: t.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AppSwitch(value: value, label: title, onChanged: onChanged),
      ],
    );
  }
}

// ── General ───────────────────────────────────────────────────────────────

class _GeneralTab extends StatelessWidget {
  const _GeneralTab({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return _Columns(
      left: const [_LanguageCard()],
      right: [
        const _AboutCard(),
        // Sign out comes back with the API (AppConfig.requireLogin).
        if (AppConfig.requireLogin) _AccountCard(user: user),
      ],
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final locale = ref.watch(localeProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(icon: Icons.translate_rounded, title: s.language, subtitle: s.languageSubtitle),
          const SizedBox(height: 18),
          AppSegmented<String>(
            selected: locale.languageCode,
            // Cross-fade: every label changes at once, so a wipe would look odd.
            onChanged: (code, _) {
              if (code == locale.languageCode) return;
              ThemeTransition.run(() => ref.read(localeProvider.notifier).set(Locale(code)));
            },
            options: const [
              SegmentOption(value: 'fa', label: 'فارسی'),
              SegmentOption(value: 'en', label: 'English'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.tokens;
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppType.label.copyWith(color: t.textMuted))),
              Text(value, style: AppType.label.copyWith(color: t.textPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(icon: Icons.info_outline_rounded, title: s.about, subtitle: AppInfo.name),
          const SizedBox(height: 8),
          row(s.version('').trim(), AppInfo.version),
          row(s.engine, 'flutter_vless 1.1.6 (Xray)'),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.tokens;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(icon: Icons.person_outline_rounded, title: s.account),
          const SizedBox(height: 18),
          Row(
            children: [
              UserAvatar(user: user, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.signedInAs, style: AppType.caption.copyWith(color: t.textFaint)),
                    Text(user.username, style: AppType.title.copyWith(color: t.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          DangerOutlineButton(
            label: s.signOut,
            icon: Icons.logout_rounded,
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
