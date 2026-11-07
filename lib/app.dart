import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_info.dart';
import 'core/l10n/locale_controller.dart';
import 'core/responsive/app_scaler.dart';
import 'core/responsive/form_factor.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/appearance_controller.dart';
import 'core/theme/theme_transition.dart';
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
      home: const AppShell(),
    );
  }
}
