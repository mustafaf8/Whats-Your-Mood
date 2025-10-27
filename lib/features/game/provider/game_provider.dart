import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/mood_card.dart';
import '../models/photo_card.dart';
import 'dart:math';

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier()
    : super(
        GameState(
          allMoodCards: _generateSampleMoodCards(),
          allPhotoCards: _generateSamplePhotoCards(),
          currentPhotoCards: [],
        ),
      ) {
    _startNewRound();
  }

  static List<MoodCard> _generateSampleMoodCards() {
    return [
      const MoodCard(id: '1', text: 'Ne zaman mutlu hissediyorum?'),
      const MoodCard(id: '2', text: 'Nerede en rahat hissediyorum?'),
      const MoodCard(
        id: '3',
        text: 'Kimle birlikte kendimi doğal hissediyorum?',
      ),
      const MoodCard(id: '4', text: 'Hangi müzik beni mutlu eder?'),
      const MoodCard(id: '5', text: 'En sevdiğim yemek nedir?'),
      const MoodCard(id: '6', text: 'En rahatladığım an?'),
      const MoodCard(id: '7', text: 'En eğlendiğim zaman?'),
      const MoodCard(id: '8', text: 'En güvende hissettiğim yer?'),
      const MoodCard(id: '9', text: 'Bana ilham veren şey?'),
      const MoodCard(id: '10', text: 'En mutlu olduğum anı?'),
    ];
  }

  static List<PhotoCard> _generateSamplePhotoCards() {
    return List.generate(
      20,
      (index) => PhotoCard(
        id: 'photo_$index',
        imagePath: 'assets/placeholder.png',
        description: 'Photo card ${index + 1}',
      ),
    );
  }

  void _startNewRound() {
    if (state.allMoodCards.isEmpty) return;

    final random = Random();

    // Random mood card seç
    final shuffledMoods = List<MoodCard>.from(state.allMoodCards)
      ..shuffle(random);
    final selectedMood = shuffledMoods[0];

    // 4 random photo card seç
    final shuffledPhotos = List<PhotoCard>.from(state.allPhotoCards)
      ..shuffle(random);
    final selectedPhotos = shuffledPhotos.take(4).toList();

    state = state.copyWith(
      currentMoodCard: () => selectedMood,
      currentPhotoCards: selectedPhotos,
      currentRound: state.currentRound + 1,
      isRevealed: false,
    );
  }

  void selectPhoto(PhotoCard photoCard) {
    if (state.isRevealed) return;

    state = state.copyWith(isRevealed: true);
  }

  void nextRound() {
    if (state.currentRound >= state.totalRounds) {
      // Oyun bitti
      return;
    }
    _startNewRound();
  }

  void resetGame() {
    state = GameState(
      allMoodCards: _generateSampleMoodCards(),
      allPhotoCards: _generateSamplePhotoCards(),
      currentPhotoCards: [],
      currentRound: 0,
      totalRounds: 10,
    );
    _startNewRound();
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>(
  (ref) => GameNotifier(),
);
