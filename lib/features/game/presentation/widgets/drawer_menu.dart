import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
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
                  "What's Your Mood",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text('🎭', style: TextStyle(fontSize: 40)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            onTap: () {
              Navigator.of(context).pop(); // Drawer'ı kapat
              // Profile route henüz eklenmedi
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil yakında gelecek')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            onTap: () {
              Navigator.of(context).pop(); // Drawer'ı kapat
              context.push('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Yardım'),
            onTap: () {
              Navigator.of(context).pop(); // Drawer'ı kapat
              // Help route henüz eklenmedi
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yardım yakında gelecek')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Hakkında'),
            onTap: () {
              Navigator.of(context).pop(); // Drawer'ı kapat
              // About route henüz eklenmedi
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hakkında yakında gelecek')),
              );
            },
          ),
        ],
      ),
    );
  }
}
