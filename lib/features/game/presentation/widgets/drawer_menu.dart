import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:whats_your_mood/l10n/app_localizations.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF00BFA5), Color(0xFFFF6F00)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  l10n.appTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('🎭', style: TextStyle(fontSize: 40)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(l10n.profile),
            onTap: () {
              Navigator.of(context).pop(); // Drawer'ı kapat
              context.push('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(l10n.settings),
            onTap: () {
              Navigator.of(context).pop(); // Drawer'ı kapat
              context.push('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: Text(l10n.help),
            onTap: () {
              Navigator.of(context).pop(); // Drawer'ı kapat
              // Help route henüz eklenmedi
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.helpComingSoon)));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(l10n.about),
            onTap: () {
              Navigator.of(context).pop(); // Drawer'ı kapat
              // About route henüz eklenmedi
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.aboutComingSoon)));
            },
          ),
        ],
      ),
    );
  }
}
