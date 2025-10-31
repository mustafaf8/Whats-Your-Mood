import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../game/data/game_repository.dart';
import '../models/game_state.dart';
import '../data/mock_card_data.dart';
import '../models/photo_card.dart';

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

    final String? currentMoodCardId = json['currentMoodCardId'] as String?;
    final moodCard = currentMoodCardId != null
        ? findMoodCardById(currentMoodCardId)
        : null;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    final userHandMap = userId != null
        ? _asMap(_asMap(players[userId])['hand'])
        : <String, dynamic>{};
    final List<PhotoCard> photoCards = userHandMap.keys
        .map((id) => findPhotoCardById(id))
        .whereType<PhotoCard>()
        .toList();

    final isRevealed = players.isNotEmpty && played.length >= players.length;

    final Map<String, String> playersUsernames = {
      for (final entry in players.entries)
        if (entry.value is Map && (entry.value as Map)['username'] != null)
          entry.key: ((entry.value as Map)['username']).toString(),
    };

    final Map<String, String> playedCardIds = {
      for (final entry in played.entries)
        if (entry.value is Map && (entry.value as Map)['cardId'] != null)
          entry.key: ((entry.value as Map)['cardId']).toString(),
    };

    final hasPlayed = userId != null && played.containsKey(userId);

    return GameState(
      allMoodCards: allMockMoodCards,
      allPhotoCards: allMockPhotoCards,
      currentPhotoCards: photoCards,
      currentRound: currentRound,
      totalRounds: (json['totalRounds'] as num?)?.toInt() ?? 10,
      isRevealed: isRevealed,
      hasPlayed: hasPlayed,
      currentMoodCard: moodCard,
      hostId: json['hostId'] as String?,
      status: (json['status'] as String?) ?? 'waiting',
      lobbyName: json['lobbyName'] as String?,
      playersUsernames: playersUsernames,
      playedCardIds: playedCardIds,
    );
  });
});
