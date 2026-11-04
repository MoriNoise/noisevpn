import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_type.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/app_card.dart';
import '../vpn/installed_apps.dart';
import '../vpn/vpn_settings.dart';

/// Pick the apps for per-app proxy. Selections save as you tap.
class AppPickerPage extends ConsumerStatefulWidget {
  const AppPickerPage({super.key});

  @override
  ConsumerState<AppPickerPage> createState() => _AppPickerPageState();
}

class _AppPickerPageState extends ConsumerState<AppPickerPage> {
  final _search = TextEditingController();
  String _query = '';

  /// Apps selected when the page opened are listed first. Taken once so
  /// rows don't jump around while tapping.
  late final Set<String> _pinned = {...ref.read(vpnSettingsProvider).selectedApps};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.tokens;
    final apps = ref.watch(installedAppsProvider);
    final selected = ref.watch(vpnSettingsProvider.select((v) => v.selectedApps));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
                    ),
                    Expanded(
                      child: Text(s.perApp, style: AppType.headline.copyWith(color: t.textPrimary, fontSize: 19)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(foregroundColor: t.accent, textStyle: AppType.label),
                      child: Text(s.done),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  style: AppType.body.copyWith(color: t.textPrimary),
                  decoration: InputDecoration(
                    hintText: s.searchApps,
                    hintStyle: AppType.body.copyWith(color: t.textFaint),
                    prefixIcon: Icon(Icons.search_rounded, size: 19, color: t.textMuted),
                    filled: true,
                    fillColor: t.surfaceRaised,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: t.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: t.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: t.accent, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: apps.when(
                    loading: () => Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: t.accent)),
                    error: (_, _) => Center(
                      child: Text(s.appsFailed, style: AppType.body.copyWith(color: t.textMuted)),
                    ),
                    data: (list) {
                      final filtered = [
                        for (final a in list)
                          if (_query.isEmpty ||
                              a.label.toLowerCase().contains(_query) ||
                              a.package.toLowerCase().contains(_query))
                            a,
                      ]..sort((a, b) {
                          final pa = _pinned.contains(a.package) ? 0 : 1;
                          final pb = _pinned.contains(b.package) ? 0 : 1;
                          return pa != pb ? pa - pb : a.label.toLowerCase().compareTo(b.label.toLowerCase());
                        });
                      if (filtered.isEmpty) {
                        return Center(child: Text(s.noAppsFound, style: AppType.body.copyWith(color: t.textMuted)));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final app = filtered[i];
                          return _AppRow(
                            app: app,
                            selected: selected.contains(app.package),
                            onTap: () => ref.read(vpnSettingsProvider.notifier).toggleApp(app.package),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.app, required this.selected, required this.onTap});

  final InstalledApp app;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = BorderRadius.circular(14);
    return Semantics(
      checked: selected,
      label: app.label,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: t.accentSoft, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      app.label.isEmpty ? '?' : app.label.substring(0, 1).toUpperCase(),
                      style: AppType.label.copyWith(color: t.accent, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.label.copyWith(color: t.textPrimary, fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                        Text(
                          app.package,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.caption.copyWith(color: t.textFaint, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: selected ? t.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: selected ? t.accent : t.borderStrong, width: 1.5),
                    ),
                    child: selected ? Icon(Icons.check_rounded, size: 14, color: t.onAccent) : null,
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
