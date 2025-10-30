import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'mock_card_data.dart';

class GameRepository {
  GameRepository(this._db);

  final FirebaseDatabase _db;

  DatabaseReference _gamesRef() => _db.ref('games');

  Future<String> createGame({
    required String hostUserId,
    required String username,
  }) async {
    final newGameRef = _gamesRef().push();
    final gameId = newGameRef.key!;

    // Deste oluşturmaları
    final random = Random();
    final moodDeck = List<String>.from(allMockMoodCards.map((m) => m.id))
      ..shuffle(random);
    final photoDeck = List<String>.from(allMockPhotoCards.map((p) => p.id))
      ..shuffle(random);

    // Host eline 5 foto kartı ver
    final hostHandIds = photoDeck.take(5).toList();
    final hostHand = {for (final id in hostHandIds) id: true};

    // İlk tur mood kartı
    final firstMoodId = moodDeck.first;

    final initial = {
      'hostId': hostUserId,
      'status': 'waiting',
      'totalRounds': 10,
      'currentRound': 1,
      'currentMoodCardId': firstMoodId,
      'players': {
        hostUserId: {'username': username, 'score': 0, 'hand': hostHand},
      },
      'rounds': {
        '1': {'moodCardId': firstMoodId, 'playedCards': {}, 'state': 'playing'},
      },
      'deck': {'moodCards': moodDeck, 'photoCards': photoDeck.skip(5).toList()},
    };

    await newGameRef.set(initial);
    return gameId;
  }

  Future<void> joinGame({
    required String gameId,
    required String userId,
    required String username,
  }) async {
    final playerRef = _gamesRef().child('$gameId/players/$userId');
    await playerRef.set({'username': username, 'score': 0, 'hand': {}});
  }

  Stream<Map<String, dynamic>?> watchGame(String gameId) {
    final ref = _gamesRef().child(gameId);
    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        return Map<String, dynamic>.from(value as Map);
      }
      return null;
    });
  }

  Future<void> playCard({
    required String gameId,
    required int round,
    required String userId,
    required String cardId,
  }) async {
    final cardRef = _gamesRef().child(
      '$gameId/rounds/$round/playedCards/$userId',
    );
    await cardRef.set({'cardId': cardId, 'votes': 0});
  }

  static Future<void> ensureAnonymousSignIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }
}
