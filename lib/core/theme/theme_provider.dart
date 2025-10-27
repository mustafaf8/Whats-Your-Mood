import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppThemeType { light, dark, custom }

class AppThemeState {
  final AppThemeType currentTheme;

  AppThemeState({required this.currentTheme});
}

class ThemeNotifier extends StateNotifier<AppThemeState> {
  ThemeNotifier() : super(AppThemeState(currentTheme: AppThemeType.light));

  void setTheme(AppThemeType theme) {
    state = AppThemeState(currentTheme: theme);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeState>(
  (ref) => ThemeNotifier(),
);
