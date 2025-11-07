import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'mock_card_data.dart';
import '../../lobby/models/lobby_info.dart';

class GameRepository {
  GameRepository(this._db);

  final FirebaseDatabase _db;

  // onDisconnect hook'larını saklamak için Map
  // Key: '${gameId}_${userId}', Value: onDisconnect nesneleri (iptal etmek için)
  final Map<String, List<OnDisconnect>> _onDisconnectHooks = {};

  DatabaseReference _gamesRef() => _db.ref('games');
  DatabaseReference _activeLobbiesRef() => _db.ref('activeLobbies');

  Future<String> createGame({
    required String hostUserId,
    required String username,
    required String lobbyName,
    String? password,
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
      'lobbyName': lobbyName,
      if (password != null) 'password': password,
      'players': {
        hostUserId: {'username': username, 'score': 0, 'hand': hostHand},
      },
      'rounds': {
        '1': {
          'moodCardId': firstMoodId,
          'playedCards': {},
          'state': 'playing',
          'roundEndTime': DateTime.now().millisecondsSinceEpoch + 45000,
        },
      },
      'deck': {'moodCards': moodDeck, 'photoCards': photoDeck.skip(5).toList()},
    };

    await newGameRef.set(initial);

    // activeLobbies e ekle (createdAt zaman damgası ile)
    await _activeLobbiesRef().child(gameId).set({
      'lobbyName': lobbyName,
      'hostUsername': username,
      'playerCount': 1,
      'maxPlayers': 6,
      'hasPassword': password != null,
      'createdAt': ServerValue.timestamp,
    });

    // Ev sahibi için onDisconnect hook'ları kur
    _setupOnDisconnectHooks(gameId, hostUserId);

    return gameId;
  }

  Future<void> joinGame({
    required String gameId,
    required String userId,
    required String username,
    String? password,
  }) async {
    // Parola kontrolü
    final passwordSnapshot = await _gamesRef()
        .child(gameId)
        .child('password')
        .get();
    final savedPassword = passwordSnapshot.value as String?;
    if (savedPassword != null && savedPassword != password) {
      throw Exception('Hatalı parola');
    }

    final gameRef = _gamesRef().child(gameId);
    await gameRef.runTransaction((mutable) {
      if (mutable is! Map) {
        return Transaction.success(mutable);
      }
      final map = Map<String, dynamic>.from(mutable);
      final deck = _asMap(map['deck']);
      final photoList = List.from((deck['photoCards'] as List?) ?? []);
      // 5 kart çek
      final take = photoList.take(5).toList();
      final remaining = photoList.skip(5).toList();
      final hand = {for (final id in take) id.toString(): true};

      // players
      final players = _asMap(map['players']);
      players[userId] = {'username': username, 'score': 0, 'hand': hand};

      deck['photoCards'] = remaining;
      map['players'] = players;
      map['deck'] = deck;

      return Transaction.success(map);
    });

    // activeLobbies e playerCount artır
    await _activeLobbiesRef()
        .child(gameId)
        .child('playerCount')
        .set(ServerValue.increment(1));

    // Oyuncu için onDisconnect hook'ları kur
    _setupOnDisconnectHooks(gameId, userId);
  }

  /// onDisconnect hook'larını kurar: bağlantı koptuğunda oyuncuyu siler ve playerCount'u azaltır
  void _setupOnDisconnectHooks(String gameId, String userId) {
    final key = '${gameId}_$userId';
    
    // Eğer zaten hook'lar varsa önce iptal et
    _cancelOnDisconnectHooks(gameId, userId);

    final playerRef = _gamesRef().child('$gameId/players/$userId');
    final playerCountRef = _activeLobbiesRef().child('$gameId/playerCount');

    // Hook 1: Oyuncuyu /games/{gameId}/players/{userId} yolundan sil
    final playerOnDisconnect = playerRef.onDisconnect();
    playerOnDisconnect.remove();

    // Hook 2: playerCount'u azalt
    final playerCountOnDisconnect = playerCountRef.onDisconnect();
    playerCountOnDisconnect.set(ServerValue.increment(-1));

    // Hook'ları sakla (iptal etmek için)
    _onDisconnectHooks[key] = [playerOnDisconnect, playerCountOnDisconnect];
  }

  /// onDisconnect hook'larını iptal eder
  void _cancelOnDisconnectHooks(String gameId, String userId) {
    final key = '${gameId}_$userId';
    final hooks = _onDisconnectHooks[key];
    
    if (hooks != null) {
      for (final hook in hooks) {
        hook.cancel();
      }
      _onDisconnectHooks.remove(key);
    }
  }

  /// Kullanıcının lobiden manuel olarak ayrılmasını yönetir
  Future<void> leaveGame({
    required String gameId,
    required String userId,
  }) async {
    // onDisconnect hook'larını iptal et (manuel ayrılma durumunda tetiklenmemeleri için)
    _cancelOnDisconnectHooks(gameId, userId);

    // Oyuncuyu /games/{gameId}/players/{userId} yolundan sil
    await _gamesRef().child('$gameId/players/$userId').remove();

    // playerCount'u azalt
    await _activeLobbiesRef()
        .child(gameId)
        .child('playerCount')
        .set(ServerValue.increment(-1));
  }

  Stream<Map<String, dynamic>?> watchGame(String gameId) {
    final ref = _gamesRef().child(gameId);
    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        return Map<String, dynamic>.from(value);
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

    // Oyun başladığında activeLobbies'den sil ve tüm onDisconnect hook'larını iptal et
    if (status == 'playing') {
      await _activeLobbiesRef().child(gameId).remove();
      
      // Oyun başladığında tüm oyuncuların onDisconnect hook'larını iptal et
      // (artık activeLobbies'de değil, oyun başladı)
      final gameSnapshot = await _gamesRef().child(gameId).child('players').get();
      if (gameSnapshot.exists && gameSnapshot.value is Map) {
        final players = Map<String, dynamic>.from(gameSnapshot.value as Map);
        for (final userId in players.keys) {
          _cancelOnDisconnectHooks(gameId, userId);
        }
      }
    }
  }

  Stream<List<LobbyInfo>> watchActiveLobbies() {
    return _activeLobbiesRef().onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <LobbyInfo>[];

      final lobbies = <LobbyInfo>[];
      for (final entry in value.entries) {
        if (entry.key is String && entry.value is Map) {
          final gameId = entry.key as String;
          final data = Map<String, dynamic>.from(entry.value as Map);
          lobbies.add(LobbyInfo.fromJson(gameId, data));
        }
      }
      return lobbies;
    });
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

  Future<void> hostNextRound(String gameId) async {
    final gameRef = _gamesRef().child(gameId);
    await gameRef.runTransaction((mutable) {
      if (mutable is! Map) return Transaction.success(mutable);
      final map = Map<String, dynamic>.from(mutable);

      final int currentRound = ((map['currentRound'] as num?)?.toInt() ?? 1);
      final int nextRound = currentRound + 1;

      // Decks
      final deck = _asMap(map['deck']);
      final moodCards = List.from((deck['moodCards'] as List?) ?? []);
      final photoCards = List.from((deck['photoCards'] as List?) ?? []);

      // Yeni mood kartı çek
      if (moodCards.isEmpty) return Transaction.success(map);
      final nextMoodId = moodCards.removeAt(0).toString();

      // Oyuncu listesi
      final players = _asMap(map['players']);

      // Her oyuncuya 1 foto kartı dağıt
      for (final entry in players.entries) {
        final pid = entry.key;
        final pdata = _asMap(entry.value);
        final hand = _asMap(pdata['hand']);
        if (photoCards.isNotEmpty) {
          final drawId = photoCards.removeAt(0).toString();
          hand[drawId] = true;
        }
        pdata['hand'] = hand;
        players[pid] = pdata;
      }

      // Rounds güncelle - List veya Map olabilir
      final rounds = _asMap(map['rounds']);
      rounds['$nextRound'] = {
        'moodCardId': nextMoodId,
        'playedCards': {},
        'state': 'playing',
        'roundEndTime': DateTime.now().millisecondsSinceEpoch + 45000,
      };

      // State yaz
      map['currentRound'] = nextRound;
      map['currentMoodCardId'] = nextMoodId;
      deck['moodCards'] = moodCards;
      deck['photoCards'] = photoCards;
      map['deck'] = deck;
      map['players'] = players;
      map['rounds'] = rounds;

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
