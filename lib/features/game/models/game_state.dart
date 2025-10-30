import 'mood_card.dart';
import 'photo_card.dart';

class GameState {
  final List<MoodCard> allMoodCards;
  final List<PhotoCard> allPhotoCards;
  final MoodCard? currentMoodCard;
  final List<PhotoCard> currentPhotoCards;
  final int currentRound;
  final int totalRounds;
  final bool isRevealed;
  final String status; // waiting | playing | finished
  final String? hostId;
  final Map<String, String> playersUsernames; // userId -> username
  final Map<String, String> playedCardIds; // userId -> photoCardId

  const GameState({
    required this.allMoodCards,
    required this.allPhotoCards,
    this.currentMoodCard,
    this.currentPhotoCards = const [],
    this.currentRound = 0,
    this.totalRounds = 10,
    this.isRevealed = false,
    this.status = 'waiting',
    this.hostId,
    this.playersUsernames = const {},
    this.playedCardIds = const {},
  });

  GameState copyWith({
    List<MoodCard>? allMoodCards,
    List<PhotoCard>? allPhotoCards,
    MoodCard? Function()? currentMoodCard,
    List<PhotoCard>? currentPhotoCards,
    int? currentRound,
    int? totalRounds,
    bool? isRevealed,
    String? status,
    String? hostId,
    Map<String, String>? playersUsernames,
    Map<String, String>? playedCardIds,
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
      status: status ?? this.status,
      hostId: hostId ?? this.hostId,
      playersUsernames: playersUsernames ?? this.playersUsernames,
      playedCardIds: playedCardIds ?? this.playedCardIds,
    );
  }
}
