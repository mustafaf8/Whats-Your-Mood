import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whats_your_mood/core/theme/theme_provider.dart';
import 'package:whats_your_mood/core/locale/locale_provider.dart';
import 'package:whats_your_mood/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final localeState = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.theme,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.light_mode),
                    title: Text(l10n.light),
                    trailing: themeState.currentTheme == AppThemeType.light
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      ref
                          .read(themeProvider.notifier)
                          .setTheme(AppThemeType.light);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: Text(l10n.dark),
                    trailing: themeState.currentTheme == AppThemeType.dark
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      ref
                          .read(themeProvider.notifier)
                          .setTheme(AppThemeType.dark);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: Text(l10n.custom),
                    trailing: themeState.currentTheme == AppThemeType.custom
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      ref
                          .read(themeProvider.notifier)
                          .setTheme(AppThemeType.custom);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Language Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.language,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(l10n.turkish),
                    subtitle: Text(l10n.turkish),
                    trailing: localeState.locale.languageCode == 'tr'
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      ref.read(localeProvider.notifier).setLocale(AppLocale.tr);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(l10n.english),
                    subtitle: Text(l10n.english),
                    trailing: localeState.locale.languageCode == 'en'
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      ref.read(localeProvider.notifier).setLocale(AppLocale.en);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(l10n.spanish),
                    subtitle: Text(l10n.spanish),
                    trailing: localeState.locale.languageCode == 'es'
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      ref.read(localeProvider.notifier).setLocale(AppLocale.es);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
