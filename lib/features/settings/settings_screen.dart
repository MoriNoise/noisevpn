import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_type.dart';
import '../../core/theme/theme_transition.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_segmented.dart';
import '../../core/widgets/appearance_controls.dart';
import '../../core/widgets/page_frame.dart';
import '../../core/widgets/primary_button.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import '../shell/app_shell.dart' show UserAvatar;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final appearance = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(icon: Icons.palette_outlined, title: s.appearance, subtitle: s.appearanceSubtitle),
          const SizedBox(height: 18),
          const AppearanceControls(),
        ],
      ),
    );
    const language = _LanguageCard();
    final account = _AccountCard(user: user);

    return PageFrame(
      title: s.navSettings,
      subtitle: s.settingsSubtitle,
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth >= 760) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: appearance),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      language,
                      if (AppConfig.requireLogin) ...[const SizedBox(height: 16), account],
                    ],
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              appearance,
              const SizedBox(height: 12),
              language,
              if (AppConfig.requireLogin) ...[const SizedBox(height: 12), account],
            ],
          );
        },
      ),
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
