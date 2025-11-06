import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../game/data/game_repository.dart';
import '../../game/provider/game_provider.dart';
import '../../game/presentation/widgets/drawer_menu.dart';
import '../models/lobby_info.dart';
import 'widgets/lobby_card_widget.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final TextEditingController _username = TextEditingController(text: 'Oyuncu');
  final TextEditingController _searchController = TextEditingController();
  bool _busy = false;
  bool _hasSearchText = false;

  late final GameRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = GameRepository(FirebaseDatabase.instance);
    GameRepository.ensureAnonymousSignIn();
  }

  @override
  void dispose() {
    _username.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCreateLobbyDialog() async {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Lobi Oluştur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Lobi Adı',
                hintText: 'Örn: Eğlenceli Grup',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Parola (Opsiyonel)',
                hintText: 'Parola boş bırakılabilir',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lütfen bir lobi adı girin')),
                );
                return;
              }
              Navigator.pop(context);
              await _createGame(
                nameController.text.trim(),
                passwordController.text.trim().isEmpty
                    ? null
                    : passwordController.text.trim(),
              );
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  Future<void> _createGame(String lobbyName, String? password) async {
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final id = await _repo.createGame(
        hostUserId: user.uid,
        username: _username.text,
        lobbyName: lobbyName,
        password: password,
      );
      if (!mounted) return;
      context.go('/lobby/$id');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinLobby(LobbyInfo lobby) async {
    String? password;
    
    if (lobby.hasPassword) {
      password = await _showPasswordDialog();
      if (password == null) return;
    }

    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await _repo.joinGame(
        gameId: lobby.gameId,
        userId: user.uid,
        username: _username.text,
        password: password,
      );
      if (!mounted) return;
      context.go('/lobby/${lobby.gameId}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Parola Gir'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Parola'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final lobbiesAsync = ref.watch(activeLobbiesProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Oyun Lobisi'),
        elevation: 0,
      ),
      drawer: const DrawerMenu(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _username,
                        decoration: const InputDecoration(
                          labelText: 'Kullanıcı adı',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Ara...',
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _hasSearchText
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _hasSearchText = false;
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _hasSearchText = value.isNotEmpty;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: lobbiesAsync.when(
                data: (lobbies) {
                  final searchQuery = _searchController.text.toLowerCase();
                  final filtered = lobbies.where((lobby) {
                    if (searchQuery.isEmpty) return true;
                    return lobby.lobbyName.toLowerCase().contains(searchQuery) ||
                        lobby.hostUsername.toLowerCase().contains(searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            searchQuery.isEmpty ? Icons.games_outlined : Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isEmpty
                                ? 'Aktif lobi yok'
                                : 'Sonuç bulunamadı',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final lobby = filtered[index];
                      return LobbyCardWidget(
                        lobby: lobby,
                        onTap: _busy || lobby.isFull ? null : () => _joinLobby(lobby),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Hata: $e'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _showCreateLobbyDialog,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Lobi'),
      ),
    );
  }
}

final activeLobbiesProvider = StreamProvider<List<LobbyInfo>>((ref) {
  final repo = ref.watch(gameRepositoryProvider);
  return repo.watchActiveLobbies();
});
