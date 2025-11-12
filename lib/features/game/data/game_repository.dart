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
    try {
      print('[GameRepository] createGame başlatıldı: $lobbyName');
      final newGameRef = _gamesRef().push();
      final gameId = newGameRef.key!;
      print('[GameRepository] Game ID oluşturuldu: $gameId');

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
          },
        },
        'deck': {'moodCards': moodDeck, 'photoCards': photoDeck.skip(5).toList()},
      };

      print('[GameRepository] Firebase\'e yazılıyor: games/$gameId');
      try {
        await newGameRef.set(initial).timeout(
          const Duration(seconds: 10),
        );
        print('[GameRepository] games/$gameId yazıldı');
      } on TimeoutException {
        print('[GameRepository] games/$gameId yazma ZAMAN AŞIMI (10 saniye)');
        throw Exception('Firebase yazma işlemi zaman aşımına uğradı. Firebase kurallarını kontrol edin.');
      } catch (e) {
        print('[GameRepository] games/$gameId yazma HATASI: $e');
        rethrow;
      }

      // activeLobbies e ekle (createdAt zaman damgası ile)
      print('[GameRepository] Firebase\'e yazılıyor: activeLobbies/$gameId');
      await _activeLobbiesRef().child(gameId).set({
        'lobbyName': lobbyName,
        'hostUsername': username,
        'playerCount': 1,
        'maxPlayers': 6,
        'hasPassword': password != null,
        'createdAt': ServerValue.timestamp,
      });
      print('[GameRepository] activeLobbies/$gameId yazıldı');

      // Ev sahibi için onDisconnect hook'ları kur (isHost: true)
      _setupOnDisconnectHooks(gameId, hostUserId, isHost: true);

      print('[GameRepository] createGame tamamlandı: $gameId');
      return gameId;
    } catch (e, stackTrace) {
      print('[GameRepository] createGame HATA: $e');
      print('[GameRepository] StackTrace: $stackTrace');
      rethrow;
    }
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

    // Oyuncu için onDisconnect hook'ları kur (isHost: false)
    // Host kontrolü için oyun verisini oku
    final gameSnapshot = await _gamesRef().child(gameId).child('hostId').get();
    final hostId = gameSnapshot.value as String?;
    final isHost = userId == hostId;
    _setupOnDisconnectHooks(gameId, userId, isHost: isHost);
  }

  /// onDisconnect hook'larını kurar: bağlantı koptuğunda oyuncuyu siler ve playerCount'u azaltır
  /// Eğer isHost true ise, host ayrıldığında tüm lobiyi siler
  void _setupOnDisconnectHooks(String gameId, String userId, {required bool isHost}) {
    final key = '${gameId}_$userId';
    
    // Eğer zaten hook'lar varsa önce iptal et
    _cancelOnDisconnectHooks(gameId, userId);

    if (isHost) {
      // Host ayrıldığında: Tüm lobiyi ve oyunu sil
      final lobbyRef = _activeLobbiesRef().child(gameId);
      final gameRef = _gamesRef().child(gameId);

      final lobbyOnDisconnect = lobbyRef.onDisconnect();
      lobbyOnDisconnect.remove();

      final gameOnDisconnect = gameRef.onDisconnect();
      gameOnDisconnect.remove();

      // Hook'ları sakla (iptal etmek için)
      _onDisconnectHooks[key] = [lobbyOnDisconnect, gameOnDisconnect];
    } else {
      // Normal oyuncu ayrıldığında: Oyuncuyu sil ve playerCount'u azalt
      final playerRef = _gamesRef().child('$gameId/players/$userId');
      final playerCountRef = _activeLobbiesRef().child('$gameId/playerCount');

      final playerOnDisconnect = playerRef.onDisconnect();
      playerOnDisconnect.remove();

      final playerCountOnDisconnect = playerCountRef.onDisconnect();
      playerCountOnDisconnect.set(ServerValue.increment(-1));

      // Hook'ları sakla (iptal etmek için)
      _onDisconnectHooks[key] = [playerOnDisconnect, playerCountOnDisconnect];
    }
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

    // Host kontrolü
    final gameSnapshot = await _gamesRef().child(gameId).get();
    if (!gameSnapshot.exists) {
      return; // Oyun zaten silinmiş
    }

    final gameData = gameSnapshot.value;
    if (gameData is! Map) {
      return;
    }

    final hostId = gameData['hostId'] as String?;

    if (userId == hostId) {
      // Host ayrıldığında: Tüm lobiyi ve oyunu sil
      await _activeLobbiesRef().child(gameId).remove();
      await _gamesRef().child(gameId).remove();
    } else {
      // Normal oyuncu ayrıldığında: Oyuncuyu sil ve playerCount'u azalt
      await _gamesRef().child('$gameId/players/$userId').remove();
      await _activeLobbiesRef()
          .child(gameId)
          .child('playerCount')
          .set(ServerValue.increment(-1));
    }
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
    final gameRef = _gamesRef().child(gameId);
    await gameRef.runTransaction((mutable) {
      if (mutable is! Map) {
        return Transaction.success(mutable);
      }

      final map = Map<String, dynamic>.from(mutable);

      // Sıra kontrolü
      final currentPlayerTurnId = map['currentPlayerTurnId'] as String?;
      if (currentPlayerTurnId != userId) {
        throw Exception('Sıra sizde değil');
      }

      final playerTurnOrder = List<String>.from(
        (map['playerTurnOrder'] as List?) ?? [],
      );

      // Kartı oyna
      final rounds = _asMap(map['rounds']);
      final roundData = _asMap(rounds['$round']);
      final playedCards = _asMap(roundData['playedCards']);
      playedCards[userId] = {'cardId': cardId, 'votes': 0};
      roundData['playedCards'] = playedCards;
      rounds['$round'] = roundData;
      map['rounds'] = rounds;

      // Sıradaki oyuncuyu belirle
      final currentIndex = playerTurnOrder.indexOf(userId);
      if (currentIndex == -1) {
        throw Exception('Oyuncu sırada bulunamadı');
      }

      final nextIndex = currentIndex + 1;

      if (nextIndex < playerTurnOrder.length) {
        // Sıradaki oyuncu var
        final nextPlayerId = playerTurnOrder[nextIndex];
        map['currentPlayerTurnId'] = nextPlayerId;
        map['turnEndTime'] = DateTime.now().millisecondsSinceEpoch + 30000; // 30 saniye
      } else {
        // Tüm oyuncular oynadı, reveal aşamasına geç
        map['currentPlayerTurnId'] = null;
        map['turnEndTime'] = null;
      }

      return Transaction.success(map);
    });
  }

  Future<void> setGameStatus(String gameId, String status) async {
    if (status == 'playing') {
      // Oyun başlatma: playerTurnOrder oluştur ve ilk sırayı ayarla
      final gameRef = _gamesRef().child(gameId);
      await gameRef.runTransaction((mutable) {
        if (mutable is! Map) {
          return Transaction.success(mutable);
        }

        final map = Map<String, dynamic>.from(mutable);
        final players = _asMap(map['players']);

        // Oyuncu ID'lerini listeye çevir ve karıştır
        final playerIds = players.keys.toList();
        playerIds.shuffle(Random());

        // İlk oyuncuyu belirle ve turnEndTime ayarla
        final firstPlayerId = playerIds.isNotEmpty ? playerIds[0] : null;
        final turnEndTime = firstPlayerId != null
            ? DateTime.now().millisecondsSinceEpoch + 30000 // 30 saniye
            : null;

        // Oyun durumunu güncelle
        map['status'] = 'playing';
        map['playerTurnOrder'] = playerIds;
        if (firstPlayerId != null) {
          map['currentPlayerTurnId'] = firstPlayerId;
          map['turnEndTime'] = turnEndTime;
        }

        return Transaction.success(map);
      });

      // activeLobbies'den sil
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
    } else {
      // Diğer status güncellemeleri için normal set
      await _gamesRef().child('$gameId/status').set(status);
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
      };

      // Yeni tur için sırayı baştan başlat
      final playerIds = players.keys.toList();
      playerIds.shuffle(Random());
      final firstPlayerId = playerIds.isNotEmpty ? playerIds[0] : null;
      final turnEndTime = firstPlayerId != null
          ? DateTime.now().millisecondsSinceEpoch + 30000 // 30 saniye
          : null;

      // State yaz
      map['currentRound'] = nextRound;
      map['currentMoodCardId'] = nextMoodId;
      map['playerTurnOrder'] = playerIds;
      if (firstPlayerId != null) {
        map['currentPlayerTurnId'] = firstPlayerId;
        map['turnEndTime'] = turnEndTime;
      }
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
      print('[GameRepository] Anonim giriş yapılıyor...');
      try {
        final userCredential = await auth.signInAnonymously();
        print('[GameRepository] Anonim giriş başarılı: ${userCredential.user?.uid}');
      } catch (e, stackTrace) {
        print('[GameRepository] Anonim giriş HATA: $e');
        print('[GameRepository] StackTrace: $stackTrace');
        rethrow;
      }
    } else {
      print('[GameRepository] Kullanıcı zaten giriş yapmış: ${auth.currentUser?.uid}');
    }
  }
}
