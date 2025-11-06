import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../models/game_state.dart';
import 'components/flame_mood_card.dart';
import 'components/flame_photo_card.dart';

class CardTableGame extends FlameGame {
  final String gameId;
  final Set<String> _activeCardIds = {};

  CardTableGame(this.gameId);

  void updateGameState(GameState gameState) {
    updateTableFromState(gameState);
  }

  void updateTableFromState(GameState gameState) {
    final newCardIds = <String>{};

    if (gameState.currentMoodCard != null) {
      final moodCardId = 'mood-${gameState.currentMoodCard!.id}';
      newCardIds.add(moodCardId);
      
      if (!_activeCardIds.contains(moodCardId)) {
        final moodCard = FlameMoodCard(
          gameState.currentMoodCard!,
          position: Vector2(size.x / 2, size.y * 0.3),
        );
        add(moodCard);
        _activeCardIds.add(moodCardId);
      }
    }

    if (gameState.isRevealed) {
      final playerCount = gameState.playedCardIds.length;
      final angleStep = (2 * 3.14159) / playerCount;
      int index = 0;

      for (final entry in gameState.playedCardIds.entries) {
        final userId = entry.key;
        final cardId = entry.value;
        final photoCardId = 'photo-$cardId-$userId';
        newCardIds.add(photoCardId);

        if (!_activeCardIds.contains(photoCardId)) {
          final angle = index * angleStep;
          final radius = size.y * 0.25;
          final centerX = size.x / 2;
          final centerY = size.y * 0.6;
          
          final targetX = centerX + radius * math.cos(angle);
          final targetY = centerY + radius * math.sin(angle);

          final photoCard = FlamePhotoCard(
            cardId: cardId,
            userId: userId,
            username: gameState.playersUsernames[userId] ?? userId,
            position: Vector2(targetX, targetY),
          );
          add(photoCard);
          _activeCardIds.add(photoCardId);
        }
        index++;
      }
    }

    _activeCardIds.removeWhere((id) => !newCardIds.contains(id));
    children.whereType<FlameMoodCard>().where((card) => !newCardIds.contains('mood-${card.moodCard.id}')).forEach((card) => card.removeFromParent());
    children.whereType<FlamePhotoCard>().where((card) => !newCardIds.contains('photo-${card.cardId}-${card.userId}')).forEach((card) => card.removeFromParent());
  }
}

