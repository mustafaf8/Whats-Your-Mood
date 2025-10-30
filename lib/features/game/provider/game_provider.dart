import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../game/data/game_repository.dart';
import '../models/game_state.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository(FirebaseDatabase.instance);
});

final gameStreamProvider = StreamProvider.family<GameState, String>((
  ref,
  gameId,
) {
  final repo = ref.watch(gameRepositoryProvider);
  return repo.watchGame(gameId).map((json) {
    if (json == null) {
      return const GameState(
        allMoodCards: [],
        allPhotoCards: [],
        currentPhotoCards: [],
      );
    }
    Map<String, dynamic> _asMap(dynamic value) {
      if (value is Map) return Map<String, dynamic>.from(value);
      if (value is List) {
        final result = <String, dynamic>{};
        for (var i = 0; i < value.length; i++) {
          final element = value[i];
          if (element != null) result['$i'] = element;
        }
        return result;
      }
      return <String, dynamic>{};
    }

    final currentRound = (json['currentRound'] as num?)?.toInt() ?? 1;
    final players = _asMap(json['players']);
    final rounds = _asMap(json['rounds']);
    final roundData = _asMap(rounds['$currentRound']);
    final played = _asMap(roundData['playedCards']);
    final isRevealed = players.isNotEmpty && played.length >= players.length;

    // Basit eşleme: eldeki kartlar yerine placeholder 4 kart
    return GameState(
      allMoodCards: const [],
      allPhotoCards: const [],
      currentPhotoCards: const [],
      currentRound: currentRound,
      totalRounds: (json['totalRounds'] as num?)?.toInt() ?? 10,
      isRevealed: isRevealed,
      currentMoodCard: null,
    );
  });
});
