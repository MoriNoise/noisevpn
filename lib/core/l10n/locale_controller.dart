import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs.dart';

class LocaleController extends Notifier<Locale> {
  static const _key = 'app.locale';
  static const supported = <Locale>[Locale('fa'), Locale('en')];

  @override
  Locale build() {
    final code = ref.watch(sharedPreferencesProvider).getString(_key);
    return supported.firstWhere(
      (l) => l.languageCode == code,
      orElse: () => supported.first,
    );
  }

  void set(Locale locale) {
    state = locale;
    ref.read(sharedPreferencesProvider).setString(_key, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);
