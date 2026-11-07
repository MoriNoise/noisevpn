import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_type.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_segmented.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../settings/settings_widgets.dart';
import 'server_models.dart';
import 'servers_controller.dart';

/// Bottom sheet on phones, dialog elsewhere.
Future<void> showAddSourceSheet(BuildContext context) {
  if (context.formFactor == FormFactor.phone) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _Frame(sheet: true, child: AddSourcePanel()),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: const _Frame(sheet: false, child: AddSourcePanel()),
      ),
    ),
  );
}

/// Edit a subscription's link, name and auto-update schedule.
Future<void> showEditSubscriptionSheet(BuildContext context, SourceData source) {
  final panel = EditSubscriptionPanel(source: source);
  if (context.formFactor == FormFactor.phone) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _Frame(sheet: true, child: panel),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: _Frame(sheet: false, child: panel),
      ),
    ),
  );
}

class _Frame extends StatelessWidget {
  const _Frame({required this.sheet, required this.child});

  final bool sheet;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final media = MediaQuery.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: sheet
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(22),
        border: Border.all(color: t.border),
        boxShadow: [BoxShadow(color: t.shadow, blurRadius: 32, offset: const Offset(0, 12))],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        sheet ? 12 : 20,
        20,
        20 + (sheet ? media.viewInsets.bottom + media.padding.bottom : 0),
      ),
      child: SingleChildScrollView(child: child),
    );
  }
}

enum _Mode { subscription, config }

class AddSourcePanel extends ConsumerStatefulWidget {
  const AddSourcePanel({super.key});

  @override
  ConsumerState<AddSourcePanel> createState() => _AddSourcePanelState();
}

class _AddSourcePanelState extends ConsumerState<AddSourcePanel> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _configs = TextEditingController();
  final _schedule = _Schedule(SubUpdateMode.provider, SubscriptionSource.defaultUpdateHours);
  _Mode _mode = _Mode.subscription;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _configs.dispose();
    _schedule.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (text == null || text.isEmpty) return;
    setState(() {
      _error = null;
      // A pasted http(s) link is a subscription; anything else is configs.
      final looksLikeUrl = !text.contains('\n') && RegExp(r'^https?://', caseSensitive: false).hasMatch(text);
      if (looksLikeUrl) {
        _mode = _Mode.subscription;
        _url.text = text;
      } else {
        _mode = _Mode.config;
        _configs.text = _configs.text.trim().isEmpty ? text : '${_configs.text.trim()}\n$text';
      }
    });
  }

  Future<void> _submit() async {
    final s = S.of(context);
    final controller = ref.read(serversControllerProvider.notifier);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_mode == _Mode.subscription) {
        final schedule = _schedule.result();
        if (schedule == null) {
          setState(() => _error = s.errHours);
          return;
        }
        final result = await controller.addSubscription(
          _url.text,
          name: _name.text,
          updateMode: schedule.$1,
          updateHours: schedule.$2,
        );
        switch (result) {
          case AddSubscriptionResult.added:
            navigator.pop();
          case AddSubscriptionResult.invalidUrl:
            setState(() => _error = s.errInvalidUrl);
          case AddSubscriptionResult.duplicate:
            setState(() => _error = s.errDuplicateSub);
        }
      } else {
        final added = await controller.addLocal(_configs.text);
        if (added == 0) {
          setState(() => _error = s.errNoConfigs);
        } else {
          navigator.pop();
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(s.configsAdded(added))));
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.tokens;
    final sheet = context.formFactor == FormFactor.phone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sheet)
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: t.borderStrong, borderRadius: BorderRadius.circular(999)),
            ),
          ),
        Row(
          children: [
            Expanded(child: Text(s.addServers, style: AppType.headline.copyWith(color: t.textPrimary, fontSize: 20))),
            TextButton.icon(
              onPressed: _busy ? null : _paste,
              style: TextButton.styleFrom(foregroundColor: t.accent, textStyle: AppType.label),
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: Text(s.paste),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppSegmented<_Mode>(
          selected: _mode,
          onChanged: (mode, _) => setState(() {
            _mode = mode;
            _error = null;
          }),
          options: [
            SegmentOption(value: _Mode.subscription, label: s.tabSubscription, icon: Icons.link_rounded),
            SegmentOption(value: _Mode.config, label: s.tabConfig, icon: Icons.description_outlined),
          ],
        ),
        const SizedBox(height: 18),
        if (_mode == _Mode.subscription) ...[
          AppTextField(
            label: s.subUrl,
            hint: 'https://',
            controller: _url,
            icon: Icons.link_rounded,
            keyboardType: TextInputType.url,
            enabled: !_busy,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: s.subName,
            controller: _name,
            icon: Icons.label_outline_rounded,
            enabled: !_busy,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 18),
          _ScheduleEditor(schedule: _schedule, enabled: !_busy, onChanged: () => setState(() => _error = null)),
        ] else
          AppTextField(
            label: s.configText,
            hint: s.configHint,
            controller: _configs,
            enabled: !_busy,
            minLines: 5,
            maxLines: 10,
          ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          NoticeBanner(message: _error!, icon: Icons.error_outline_rounded, color: t.danger),
        ],
        const SizedBox(height: 20),
        PrimaryButton(label: s.add, icon: Icons.add_rounded, loading: _busy, onPressed: _submit),
      ],
    );
  }
}

// ── Edit ──────────────────────────────────────────────────────────────────

class EditSubscriptionPanel extends ConsumerStatefulWidget {
  const EditSubscriptionPanel({super.key, required this.source});

  final SourceData source;

  @override
  ConsumerState<EditSubscriptionPanel> createState() => _EditSubscriptionPanelState();
}

class _EditSubscriptionPanelState extends ConsumerState<EditSubscriptionPanel> {
  late final _name = TextEditingController(text: widget.source.name);
  late final _url = TextEditingController(text: widget.source.url ?? '');
  late final _schedule = _Schedule(
    widget.source.subscription?.updateMode ?? SubUpdateMode.provider,
    widget.source.subscription?.updateHours ?? SubscriptionSource.defaultUpdateHours,
  );
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _schedule.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = S.of(context);
    final navigator = Navigator.of(context);
    final schedule = _schedule.result();
    if (schedule == null) {
      setState(() => _error = s.errHours);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(serversControllerProvider.notifier).editSubscription(
            widget.source.id,
            url: _url.text,
            name: _name.text,
            updateMode: schedule.$1,
            updateHours: schedule.$2,
          );
      switch (result) {
        case EditSubscriptionResult.saved:
        case EditSubscriptionResult.notFound:
          navigator.pop();
        case EditSubscriptionResult.invalidUrl:
          setState(() => _error = s.errInvalidUrl);
        case EditSubscriptionResult.duplicate:
          setState(() => _error = s.errDuplicateSub);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.tokens;
    final sheet = context.formFactor == FormFactor.phone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sheet)
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: t.borderStrong, borderRadius: BorderRadius.circular(999)),
            ),
          ),
        Text(s.editSubscription, style: AppType.headline.copyWith(color: t.textPrimary, fontSize: 20)),
        const SizedBox(height: 18),
        AppTextField(
          label: s.subUrl,
          hint: 'https://',
          controller: _url,
          icon: Icons.link_rounded,
          keyboardType: TextInputType.url,
          enabled: !_busy,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: s.subName,
          controller: _name,
          icon: Icons.label_outline_rounded,
          enabled: !_busy,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 18),
        _ScheduleEditor(
          schedule: _schedule,
          enabled: !_busy,
          providerHours: widget.source.providerHours,
          onChanged: () => setState(() => _error = null),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          NoticeBanner(message: _error!, icon: Icons.error_outline_rounded, color: t.danger),
        ],
        const SizedBox(height: 20),
        PrimaryButton(label: s.save, icon: Icons.check_rounded, loading: _busy, onPressed: _save),
      ],
    );
  }
}

// ── Auto-update schedule ──────────────────────────────────────────────────

enum _Choice { off, provider, h6, h12, h24, custom }

/// The schedule being edited: a choice plus the custom-hours text.
class _Schedule {
  _Schedule(SubUpdateMode mode, int hours)
      : choice = switch (mode) {
          SubUpdateMode.off => _Choice.off,
          SubUpdateMode.provider => _Choice.provider,
          SubUpdateMode.interval => switch (hours) {
              6 => _Choice.h6,
              12 => _Choice.h12,
              24 => _Choice.h24,
              _ => _Choice.custom,
            },
        },
        hours = TextEditingController(text: '$hours');

  _Choice choice;
  final TextEditingController hours;

  int? get _typedHours {
    final h = int.tryParse(hours.text.trim());
    return h != null && h >= SubscriptionSource.minUpdateHours && h <= SubscriptionSource.maxUpdateHours ? h : null;
  }

  /// Hours used by "as the subscription says" when the panel sends none.
  int get fallbackHours => _typedHours ?? SubscriptionSource.defaultUpdateHours;

  /// The mode and hours to save, or null when the custom hours are invalid.
  (SubUpdateMode, int)? result() => switch (choice) {
        _Choice.off => (SubUpdateMode.off, fallbackHours),
        _Choice.provider => (SubUpdateMode.provider, fallbackHours),
        _Choice.h6 => (SubUpdateMode.interval, 6),
        _Choice.h12 => (SubUpdateMode.interval, 12),
        _Choice.h24 => (SubUpdateMode.interval, 24),
        _Choice.custom => _typedHours == null ? null : (SubUpdateMode.interval, _typedHours!),
      };

  void dispose() => hours.dispose();
}

class _ScheduleEditor extends StatelessWidget {
  const _ScheduleEditor({
    required this.schedule,
    required this.enabled,
    required this.onChanged,
    this.providerHours,
  });

  final _Schedule schedule;
  final bool enabled;
  final VoidCallback onChanged;

  /// What the subscription itself asked for, when it is known.
  final double? providerHours;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.tokens;
    final choice = schedule.choice;

    final String hint = switch (choice) {
      _Choice.provider => providerHours != null
          ? s.providerSays(s.hoursShort(providerHours!))
          : s.updateProviderHint(s.hoursShort(schedule.fallbackHours.toDouble())),
      _Choice.off => s.autoUpdateHint,
      _ => s.autoUpdateHint,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceRow<_Choice>(
          title: s.autoUpdate,
          selected: choice,
          options: [
            (_Choice.off, s.updateOff),
            (_Choice.provider, s.updateProvider),
            (_Choice.h6, s.updateEvery(s.hoursShort(6))),
            (_Choice.h12, s.updateEvery(s.hoursShort(12))),
            (_Choice.h24, s.updateEvery(s.hoursShort(24))),
            (_Choice.custom, s.updateCustom),
          ],
          onChanged: enabled
              ? (v) {
                  schedule.choice = v;
                  onChanged();
                }
              : null,
        ),
        if (choice == _Choice.custom) ...[
          const SizedBox(height: 14),
          AppTextField(
            label: s.updateHoursLabel,
            hint: '${SubscriptionSource.minUpdateHours}–${SubscriptionSource.maxUpdateHours}',
            controller: schedule.hours,
            icon: Icons.schedule_rounded,
            keyboardType: TextInputType.number,
            enabled: enabled,
            textInputAction: TextInputAction.done,
          ),
        ],
        const SizedBox(height: 8),
        Text(hint, style: AppType.caption.copyWith(color: t.textMuted)),
      ],
    );
  }
}
