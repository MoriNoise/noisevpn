import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_type.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_segmented.dart';
import '../vpn/engine_info.dart';
import '../vpn/vpn_backend.dart';
import '../vpn/vpn_controller.dart';
import '../vpn/vpn_settings.dart';
import 'settings_widgets.dart';

bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
bool get _apple => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

/// Hands changed engine options to flutter_vless. While a session runs they
/// wait for the next connect (Apple needs the tunnel stopped for this).
Future<void> _applyEngine(WidgetRef ref) async {
  final applied = await ref.read(vpnControllerProvider.notifier).applyEngineOptionsNow();
  if (applied) ref.invalidate(engineCapabilitiesProvider);
}

void _changeEngine(WidgetRef ref, VpnSettings Function(VpnSettings) change) {
  ref.read(vpnSettingsProvider.notifier).update(change);
  _applyEngine(ref);
}

class AdvancedTab extends ConsumerWidget {
  const AdvancedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.tokens;
    final supported = ref.watch(vpnBackendProvider).isSupported;
    if (!supported) {
      return NoticeBanner(message: s.notAvailableOn(AppConfig.platformName), icon: Icons.info_outline_rounded, color: t.info);
    }
    final caps = ref.watch(engineCapabilitiesProvider).valueOrNull;
    final optionsError = ref.watch(vpnBackendProvider).optionsError;
    final active = ref.watch(vpnControllerProvider.select((v) => v.isActive));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active) ...[
          NoticeBanner(message: s.applyOnReconnect, icon: Icons.info_outline_rounded, color: t.info),
          const SizedBox(height: 12),
        ],
        if (optionsError != null) ...[
          NoticeBanner(message: s.optionsRefused(optionsError), icon: Icons.warning_amber_rounded, color: t.warning),
          const SizedBox(height: 12),
        ],
        SettingsColumns(
          left: [_ReconnectCard(caps: caps), const _DiagnosticsCard()],
          right: [_ProtectionCard(caps: caps), _SystemCard(caps: caps)],
        ),
      ],
    );
  }
}

// ── Reconnect ─────────────────────────────────────────────────────────────

class _ReconnectCard extends ConsumerWidget {
  const _ReconnectCard({required this.caps});

  final EngineCapabilities? caps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final settings = ref.watch(vpnSettingsProvider);
    final custom = caps?.customReconnect ?? false;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(icon: Icons.autorenew_rounded, title: s.reconnect, subtitle: s.reconnectHint),
          const SizedBox(height: 16),
          SwitchRow(
            title: s.autoReconnect,
            hint: s.autoReconnectHint,
            value: settings.autoReconnect,
            onChanged: (v) => _changeEngine(ref, (x) => x.copyWith(autoReconnect: v)),
          ),
          if (settings.autoReconnect && custom) ...[
            const SizedBox(height: 18),
            ChoiceRow<int>(
              title: s.reconnectAttempts,
              selected: settings.reconnectAttempts,
              options: [
                for (final n in VpnSettings.attemptChoices) (n, n == 0 ? s.unlimited : s.n('$n')),
              ],
              onChanged: (v) => _changeEngine(ref, (x) => x.copyWith(reconnectAttempts: v)),
            ),
            const SizedBox(height: 18),
            ChoiceRow<int>(
              title: s.reconnectMaxDelay,
              selected: settings.reconnectMaxDelay,
              options: [for (final n in VpnSettings.maxDelayChoices) (n, s.seconds(n))],
              onChanged: (v) => _changeEngine(ref, (x) => x.copyWith(reconnectMaxDelay: v)),
            ),
          ],
          if (_apple && (caps?.onDemand ?? false)) ...[
            const SizedBox(height: 18),
            ChoiceRow<OnDemandChoice>(
              title: s.onDemand,
              hint: s.onDemandHint,
              selected: settings.onDemand,
              options: [
                (OnDemandChoice.auto, s.optAuto),
                // On Demand needs automatic reconnect.
                if (settings.autoReconnect) (OnDemandChoice.on, s.optOn),
                (OnDemandChoice.off, s.optOff),
              ],
              onChanged: (v) => _changeEngine(ref, (x) => x.copyWith(onDemand: v)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Protection ────────────────────────────────────────────────────────────

class _ProtectionCard extends ConsumerStatefulWidget {
  const _ProtectionCard({required this.caps});

  final EngineCapabilities? caps;

  @override
  ConsumerState<_ProtectionCard> createState() => _ProtectionCardState();
}

class _ProtectionCardState extends ConsumerState<_ProtectionCard> {
  // Always-on is changed in system settings; read it again on return.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(engineCapabilitiesProvider));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.tokens;
    final settings = ref.watch(vpnSettingsProvider);
    final caps = widget.caps;
    final alwaysOn = _android && (caps?.alwaysOn ?? false);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(icon: Icons.shield_outlined, title: s.protection, subtitle: s.protectionHint),
          const SizedBox(height: 16),
          Text(s.killSwitchNote, style: AppType.caption.copyWith(color: t.textMuted)),
          if (alwaysOn) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  caps!.alwaysOnEnabled ? Icons.verified_user_outlined : Icons.gpp_maybe_outlined,
                  size: 18,
                  color: caps.alwaysOnEnabled ? t.success : t.textFaint,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.alwaysOnStatus(caps.alwaysOnEnabled, caps.lockdownEnabled),
                    style: AppType.label.copyWith(color: t.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchRow(
              title: s.requireAlwaysOn,
              hint: s.requireAlwaysOnHint,
              value: settings.requireAlwaysOn,
              onChanged: (v) => _changeEngine(ref, (x) => x.copyWith(requireAlwaysOn: v)),
            ),
          ],
          if (_android) ...[
            const SizedBox(height: 16),
            SettingsButton(
              icon: Icons.open_in_new_rounded,
              label: s.openVpnSettings,
              onPressed: openSystemVpnSettings,
            ),
          ],
        ],
      ),
    );
  }
}

// ── System controls ───────────────────────────────────────────────────────

class _SystemCard extends ConsumerWidget {
  const _SystemCard({required this.caps});

  final EngineCapabilities? caps;

  void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.tokens;
    final settings = ref.watch(vpnSettingsProvider);
    final quick = caps?.quickAccess ?? false;
    // Desktop controls need the open desktop session anyway.
    final touch = _android || defaultTargetPlatform == TargetPlatform.iOS;

    if (!_android && !quick) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(icon: Icons.toggle_on_outlined, title: s.systemControls, subtitle: s.systemControlsHint),
          const SizedBox(height: 16),
          if (_android) ...[
            ChoiceRow<NotificationButton>(
              title: s.notificationButton,
              selected: settings.notificationButton,
              options: [
                (NotificationButton.disconnect, s.notifDisconnect),
                (NotificationButton.openApp, s.notifOpenApp),
                (NotificationButton.none, s.notifNone),
              ],
              onChanged: (v) => _changeEngine(ref, (x) => x.copyWith(notificationButton: v)),
            ),
            const SizedBox(height: 18),
          ],
          SwitchRow(
            title: s.quickAccess,
            hint: quick ? s.quickAccessHint(AppConfig.platformName) : s.quickUnavailable,
            value: settings.quickAccess && quick,
            onChanged: quick ? (v) => _changeEngine(ref, (x) => x.copyWith(quickAccess: v)) : null,
          ),
          if (quick && settings.quickAccess) ...[
            if (touch) ...[
              const SizedBox(height: 16),
              SwitchRow(
                title: s.quickAccessUnlock,
                hint: s.quickAccessUnlockHint,
                value: settings.quickAccessUnlock,
                onChanged: (v) => _changeEngine(ref, (x) => x.copyWith(quickAccessUnlock: v)),
              ),
            ],
            const SizedBox(height: 16),
            Text(s.quickAccessAction, style: AppType.label.copyWith(color: t.textPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            AppSegmented<bool>(
              selected: settings.quickAccessOpensApp,
              onChanged: (v, _) => _changeEngine(ref, (x) => x.copyWith(quickAccessOpensApp: v)),
              options: [
                SegmentOption(value: false, label: s.quickToggle),
                SegmentOption(value: true, label: s.quickOpenApp),
              ],
            ),
            const SizedBox(height: 16),
            if (_android && (caps?.addQuickTile ?? false)) ...[
              SettingsButton(
                icon: Icons.add_box_outlined,
                label: s.addTile,
                onPressed: () async {
                  final result = await ref.read(vpnBackendProvider).addQuickTile();
                  if (!context.mounted) return;
                  _snack(context, switch (result) {
                    QuickTileResult.added => s.tileAdded,
                    QuickTileResult.alreadyAdded => s.tileAlreadyAdded,
                    QuickTileResult.declined => s.tileDeclined,
                    QuickTileResult.unsupported => s.quickUnavailable,
                  });
                },
              ),
              const SizedBox(height: 10),
            ],
            SettingsButton(
              icon: Icons.delete_sweep_outlined,
              label: s.clearQuickProfile,
              onPressed: () async {
                try {
                  await ref.read(vpnBackendProvider).clearQuickAccess();
                  if (context.mounted) _snack(context, s.quickProfileCleared);
                } catch (_) {
                  if (context.mounted) _snack(context, s.quickUnavailable);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ── Diagnostics ───────────────────────────────────────────────────────────

class _DiagnosticsCard extends ConsumerStatefulWidget {
  const _DiagnosticsCard();

  @override
  ConsumerState<_DiagnosticsCard> createState() => _DiagnosticsCardState();
}

class _DiagnosticsCardState extends ConsumerState<_DiagnosticsCard> {
  bool _testing = false;

  /// null = not tested; 0 = failed; otherwise ms.
  int? _result;

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _result = null;
    });
    final ms = await ref.read(vpnBackendProvider).connectedDelay();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _result = ms ?? 0;
    });
  }

  Future<void> _showLog() async {
    final log = await ref.read(vpnBackendProvider).diagnostics();
    if (!mounted) return;
    await showDialog<void>(context: context, builder: (_) => _LogDialog(log: log));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.tokens;
    final settings = ref.watch(vpnSettingsProvider);
    final connected = ref.watch(vpnControllerProvider.select((v) => v.phase == VpnPhase.connected));

    final result = _result;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(icon: Icons.monitor_heart_outlined, title: s.diagnostics, subtitle: s.diagnosticsHint),
          const SizedBox(height: 16),
          SwitchRow(
            title: s.collectLogs,
            hint: null,
            value: settings.diagnostics,
            onChanged: (v) => _changeEngine(ref, (x) => x.copyWith(diagnostics: v)),
          ),
          const SizedBox(height: 16),
          SettingsButton(icon: Icons.receipt_long_outlined, label: s.viewLog, onPressed: _showLog),
          if (connected) ...[
            const SizedBox(height: 10),
            SettingsButton(
              icon: Icons.network_check_rounded,
              label: _testing ? s.checking : s.testConnection,
              onPressed: _testing ? null : _test,
            ),
            const SizedBox(height: 8),
            Text(
              result == null ? s.testConnectionHint : (result > 0 ? s.connectionOk(s.ms(result)) : s.connectionFailed),
              style: AppType.caption.copyWith(
                color: result == null ? t.textMuted : (result > 0 ? t.success : t.danger),
                fontWeight: result == null ? null : FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogDialog extends StatelessWidget {
  const _LogDialog({required this.log});

  final String log;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.tokens;
    final empty = log.trim().isEmpty;
    return AlertDialog(
      backgroundColor: t.surface,
      title: Text(s.diagnostics, style: AppType.title.copyWith(color: t.textPrimary)),
      content: SizedBox(
        width: 640,
        height: 420,
        child: empty
            ? Center(child: Text(s.logEmpty, textAlign: TextAlign.center, style: AppType.label.copyWith(color: t.textMuted)))
            : Directionality(
                textDirection: TextDirection.ltr,
                child: SingleChildScrollView(
                  child: SelectableText(
                    log,
                    style: AppType.caption.copyWith(color: t.textPrimary, fontFamily: 'monospace', height: 1.4),
                  ),
                ),
              ),
      ),
      actions: [
        if (!empty)
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: log));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(s.copied)));
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(s.copy),
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.done)),
      ],
    );
  }
}
