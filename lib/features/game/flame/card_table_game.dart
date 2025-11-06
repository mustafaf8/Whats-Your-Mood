import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import '../models/game_state.dart';
import 'components/flame_mood_card.dart';
import 'components/flame_photo_card.dart';

class CardTableGame extends FlameGame {
  final String gameId;
  final Set<String> _activeCardIds = {};
  Component? _tableBackground;

  CardTableGame(this.gameId);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loadTableBackground();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_tableBackground != null && size.x > 0 && size.y > 0) {
      if (_tableBackground is SpriteComponent) {
        (_tableBackground as SpriteComponent).size = size;
      } else if (_tableBackground is RectangleComponent) {
        (_tableBackground as RectangleComponent).size = size;
      }
    } else if (_tableBackground == null) {
      _loadTableBackground();
    }
  }

  Future<void> _loadTableBackground() async {
    if (size.x == 0 || size.y == 0) return;

    try {
      final tableSprite = await Sprite.load('table_felt.png');
      _tableBackground = SpriteComponent(
        sprite: tableSprite,
        size: size,
        anchor: Anchor.topLeft,
      )..priority = -1;
      add(_tableBackground!);
    } catch (e) {
      try {
        final tableSprite = await Sprite.load('paper.png');
        _tableBackground = SpriteComponent(
          sprite: tableSprite,
          size: size,
          anchor: Anchor.topLeft,
        )..priority = -1;
        add(_tableBackground!);
      } catch (_) {
        _tableBackground = RectangleComponent(
          size: size,
          paint: Paint()..color = const Color(0xFF2D5016),
        )..priority = -1;
        add(_tableBackground!);
      }
    }
  }

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
          position: Vector2(size.x / 2, size.y * 0.25),
        );
        add(moodCard);
        _activeCardIds.add(moodCardId);
      }
    }

    if (gameState.isRevealed) {
      final playerCount = gameState.playedCardIds.length;
      final double fanAngle = 1.2;
      final double startAngle = -(fanAngle / 2);
      final double angleStep = playerCount > 1 ? fanAngle / (playerCount - 1) : 0;
      final double radius = size.y * 0.45;
      final fanCenter = Vector2(size.x / 2, size.y * 0.65);

      int index = 0;

      for (final entry in gameState.playedCardIds.entries) {
        final userId = entry.key;
        final cardId = entry.value;
        final photoCardId = 'photo-$cardId-$userId';
        newCardIds.add(photoCardId);

        if (!_activeCardIds.contains(photoCardId)) {
          final angle = startAngle + (index * angleStep);
          
          final targetX = fanCenter.x + radius * math.sin(angle);
          final targetY = fanCenter.y + radius * math.cos(angle);

          final photoCard = FlamePhotoCard(
            cardId: cardId,
            userId: userId,
            username: gameState.playersUsernames[userId] ?? userId,
            position: Vector2(targetX, targetY),
          );
          
          photoCard.angle = angle * 0.8;
          
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

