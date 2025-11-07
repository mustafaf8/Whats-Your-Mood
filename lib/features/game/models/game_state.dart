import 'mood_card.dart';
import 'photo_card.dart';
import 'player_status.dart';

class GameState {
  final List<MoodCard> allMoodCards;
  final List<PhotoCard> allPhotoCards;
  final MoodCard? currentMoodCard;
  final List<PhotoCard> currentPhotoCards;
  final int currentRound;
  final int totalRounds;
  final bool isRevealed;
  final bool hasPlayed;
  final String status; // waiting | playing | finished
  final String? hostId;
  final String? lobbyName;
  final Map<String, String> playersUsernames; // userId -> username
  final Map<String, String> playedCardIds; // userId -> photoCardId
  final List<String> playerTurnOrder; // Oyun başladığında belirlenen oyuncu sırası
  final String? currentPlayerTurnId; // Sırası gelen oyuncunun ID'si
  final DateTime? turnEndTime; // Sırası gelen oyuncunun hamlesi için son tarih/saat
  final List<PlayerStatus> players;

  const GameState({
    required this.allMoodCards,
    required this.allPhotoCards,
    this.currentMoodCard,
    this.currentPhotoCards = const [],
    this.currentRound = 0,
    this.totalRounds = 10,
    this.isRevealed = false,
    this.hasPlayed = false,
    this.status = 'waiting',
    this.hostId,
    this.lobbyName,
    this.playersUsernames = const {},
    this.playedCardIds = const {},
    this.playerTurnOrder = const [],
    this.currentPlayerTurnId,
    this.turnEndTime,
    this.players = const [],
  });

  GameState copyWith({
    List<MoodCard>? allMoodCards,
    List<PhotoCard>? allPhotoCards,
    MoodCard? Function()? currentMoodCard,
    List<PhotoCard>? currentPhotoCards,
    int? currentRound,
    int? totalRounds,
    bool? isRevealed,
    bool? hasPlayed,
    String? status,
    String? hostId,
    String? lobbyName,
    Map<String, String>? playersUsernames,
    Map<String, String>? playedCardIds,
    List<String>? playerTurnOrder,
    String? Function()? currentPlayerTurnId,
    DateTime? Function()? turnEndTime,
    List<PlayerStatus>? players,
  }) {
    return GameState(
      allMoodCards: allMoodCards ?? this.allMoodCards,
      allPhotoCards: allPhotoCards ?? this.allPhotoCards,
      currentMoodCard: currentMoodCard != null
          ? currentMoodCard()
          : this.currentMoodCard,
      currentPhotoCards: currentPhotoCards ?? this.currentPhotoCards,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      isRevealed: isRevealed ?? this.isRevealed,
      hasPlayed: hasPlayed ?? this.hasPlayed,
      status: status ?? this.status,
      hostId: hostId ?? this.hostId,
      lobbyName: lobbyName ?? this.lobbyName,
      playersUsernames: playersUsernames ?? this.playersUsernames,
      playedCardIds: playedCardIds ?? this.playedCardIds,
      playerTurnOrder: playerTurnOrder ?? this.playerTurnOrder,
      currentPlayerTurnId: currentPlayerTurnId != null
          ? currentPlayerTurnId()
          : this.currentPlayerTurnId,
      turnEndTime: turnEndTime != null ? turnEndTime() : this.turnEndTime,
      players: players ?? this.players,
    );
  }
}
