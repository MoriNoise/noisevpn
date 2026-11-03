import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_info.dart';
import 'core/config/app_config.dart';
import 'core/l10n/locale_controller.dart';
import 'core/responsive/app_scaler.dart';
import 'core/responsive/form_factor.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/appearance_controller.dart';
import 'core/theme/theme_transition.dart';
import 'core/widgets/ambient_background.dart';
import 'core/widgets/brand_mark.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/app_shell.dart';

class NoiseApp extends ConsumerWidget {
  const NoiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final locale = ref.watch(localeProvider);
    final persian = locale.languageCode == 'fa';

    ThemeData theme(Brightness b) => buildAppTheme(
          brightness: b,
          accent: appearance.accent,
          persian: persian,
          glass: appearance.glass,
        );

    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      themeMode: appearance.mode,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      // ThemeTransition animates every change; Material's own cross-fade
      // would only reach part of the tree and look like tearing.
      themeAnimationDuration: Duration.zero,
      builder: (context, child) {
        // Decided from the real window, before any scaling.
        final factor = FormFactor.resolve(MediaQuery.sizeOf(context));

        Widget content = ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            // When the phone layout runs on a computer, let the mouse drag too.
            dragDevices: factor.isTouch ? PointerDeviceKind.values.toSet() : null,
          ),
          child: child ?? const SizedBox.shrink(),
        );

        content = factor.isDesktop
            ? AppScaler(child: content)
            : MediaQuery.withClampedTextScaling(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.1,
                child: content,
              );

        // Same left-to-right layout in Persian and English: switching the
        // language changes the text, not the position of anything.
        return Directionality(
          textDirection: TextDirection.ltr,
          child: FormFactorScope(
            factor: factor,
            child: ThemeTransition(
              enabled: !MediaQuery.disableAnimationsOf(context),
              child: content,
            ),
          ),
        );
      },
      home: const _Root(),
    );
  }
}

/// Stands in for a signed-in account while [AppConfig.requireLogin] is off.
const _localUser = AuthUser(username: 'Noise');

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Login is parked until the API exists; the screen and its code stay.
    if (!AppConfig.requireLogin) {
      return const AppShell(key: ValueKey('shell'), user: _localUser);
    }
    final auth = ref.watch(authControllerProvider);
    final Widget child = auth.when(
      data: (user) => user == null
          ? const LoginScreen(key: ValueKey('login'))
          : AppShell(key: const ValueKey('shell'), user: user),
      loading: () => const _Splash(key: ValueKey('splash')),
      error: (_, _) => const LoginScreen(key: ValueKey('login')),
    );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      child: child,
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AmbientBackground(child: Center(child: BrandMark(size: 56))),
    );
  }
}
