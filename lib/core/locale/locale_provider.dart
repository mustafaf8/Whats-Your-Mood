import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLocale { tr, en, es }

class LocaleState {
  final Locale locale;

  LocaleState({required this.locale});
}

class LocaleNotifier extends StateNotifier<LocaleState> {
  LocaleNotifier() : super(LocaleState(locale: const Locale('tr')));

  void setLocale(AppLocale locale) {
    late final Locale newLocale;
    switch (locale) {
      case AppLocale.tr:
        newLocale = const Locale('tr');
        break;
      case AppLocale.en:
        newLocale = const Locale('en');
        break;
      case AppLocale.es:
        newLocale = const Locale('es');
        break;
    }
    state = LocaleState(locale: newLocale);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleState>(
  (ref) => LocaleNotifier(),
);
