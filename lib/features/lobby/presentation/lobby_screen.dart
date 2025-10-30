import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../game/data/game_repository.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _username = TextEditingController(text: 'Oyuncu');
  final TextEditingController _gameId = TextEditingController();
  bool _busy = false;

  late final GameRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = GameRepository(FirebaseDatabase.instance);
    GameRepository.ensureAnonymousSignIn();
  }

  Future<void> _createGame() async {
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final id = await _repo.createGame(
        hostUserId: user.uid,
        username: _username.text,
      );
      if (!mounted) return;
      context.go('/game/$id');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinGame() async {
    if (_gameId.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await _repo.joinGame(
        gameId: _gameId.text.trim(),
        userId: user.uid,
        username: _username.text,
      );
      if (!mounted) return;
      context.go('/game/${_gameId.text.trim()}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oyun Lobisi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Kullanıcı adı'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _createGame,
              child: const Text('Oyun Yarat'),
            ),
            const Divider(height: 32),
            TextField(
              controller: _gameId,
              decoration: const InputDecoration(labelText: 'Game ID ile Katıl'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _joinGame,
              child: const Text('Katıl'),
            ),
          ],
        ),
      ),
    );
  }
}
