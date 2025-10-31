import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../game/provider/game_provider.dart';

class LobbyWaitingScreen extends ConsumerWidget {
  const LobbyWaitingScreen({super.key, required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGame = ref.watch(gameStreamProvider(gameId));
    return asyncGame.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Hata: $e'))),
      data: (state) {
        if (state.status == 'playing') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/game/$gameId');
          });
        }
        final userId = FirebaseAuth.instance.currentUser?.uid;
        final isHost = userId != null && userId == state.hostId;
        final players = state.playersUsernames;
        return Scaffold(
          appBar: AppBar(title: Text(state.lobbyName ?? 'Bekleme Odası')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Katılan Oyuncular:'),
                const SizedBox(height: 8),
                ...players.entries.map((e) => ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(e.value),
                      subtitle: Text(e.key),
                    )),
                const Spacer(),
                if (isHost)
                  ElevatedButton(
                    onPressed: () async {
                      await ref.read(gameRepositoryProvider).setGameStatus(gameId, 'playing');
                    },
                    child: const Text('Oyunu Başlat'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}


