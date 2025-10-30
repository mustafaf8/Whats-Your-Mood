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
    final gameRef = _gamesRef().child(gameId);
    await gameRef.runTransaction((mutable) {
      if (mutable is! Map) {
        return Transaction.success(mutable);
      }
      final map = Map<String, dynamic>.from(mutable as Map);
      final deck = Map<String, dynamic>.from((map['deck'] as Map?) ?? {});
      final photoList = List.from((deck['photoCards'] as List?) ?? []);
      // 5 kart çek
      final take = photoList.take(5).toList();
      final remaining = photoList.skip(5).toList();
      final hand = {for (final id in take) id.toString(): true};

      // players
      final players = Map<String, dynamic>.from((map['players'] as Map?) ?? {});
      players[userId] = {'username': username, 'score': 0, 'hand': hand};

      deck['photoCards'] = remaining;
      map['players'] = players;
      map['deck'] = deck;

      return Transaction.success(map);
    });
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

  Future<void> setGameStatus(String gameId, String status) async {
    await _gamesRef().child('$gameId/status').set(status);
  }

  Future<void> hostNextRound(String gameId) async {
    final gameRef = _gamesRef().child(gameId);
    await gameRef.runTransaction((mutable) {
      if (mutable is! Map) return Transaction.success(mutable);
      final map = Map<String, dynamic>.from(mutable as Map);

      final int currentRound = ((map['currentRound'] as num?)?.toInt() ?? 1);
      final int nextRound = currentRound + 1;

      // Decks
      final deck = Map<String, dynamic>.from((map['deck'] as Map?) ?? {});
      final moodCards = List.from((deck['moodCards'] as List?) ?? []);
      final photoCards = List.from((deck['photoCards'] as List?) ?? []);

      // Yeni mood kartı çek
      if (moodCards.isEmpty) return Transaction.success(map);
      final nextMoodId = moodCards.removeAt(0).toString();

      // Oyuncu listesi
      final players = Map<String, dynamic>.from((map['players'] as Map?) ?? {});

      // Her oyuncuya 1 foto kartı dağıt
      for (final entry in players.entries) {
        final pid = entry.key;
        final pdata = Map<String, dynamic>.from((entry.value as Map?) ?? {});
        final hand = Map<String, dynamic>.from((pdata['hand'] as Map?) ?? {});
        if (photoCards.isNotEmpty) {
          final drawId = photoCards.removeAt(0).toString();
          hand[drawId] = true;
        }
        pdata['hand'] = hand;
        players[pid] = pdata;
      }

      // Rounds güncelle
      final rounds = Map<String, dynamic>.from((map['rounds'] as Map?) ?? {});
      rounds['$nextRound'] = {
        'moodCardId': nextMoodId,
        'playedCards': {},
        'state': 'playing',
      };

      // State yaz
      map['currentRound'] = nextRound;
      map['currentMoodCardId'] = nextMoodId;
      deck['moodCards'] = moodCards;
      deck['photoCards'] = photoCards;
      map['deck'] = deck;
      map['players'] = players;

      return Transaction.success(map);
    });
  }

  static Future<void> ensureAnonymousSignIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }
}
