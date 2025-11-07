import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import '../models/game_state.dart';
import 'components/flame_mood_card.dart';
import 'components/flame_photo_card.dart';
import 'components/tiled_sprite_component.dart';

class CardTableGame extends FlameGame {
  final String gameId;
  final Set<String> _activeCardIds = {};
  Component? _tableBackground;
  bool _isSizeReady = false;
  GameState? _pendingGameState;
  Vector2 _currentSize = Vector2.zero();
  bool _isLoadingBackground = false;

  CardTableGame(this.gameId);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _currentSize = size;
    _isSizeReady = size.x > 0 && size.y > 0;

    if (_isSizeReady) {
      if (_tableBackground == null && !_isLoadingBackground) {
        _loadTableBackground();
      } else if (_tableBackground != null) {
        if (_tableBackground is TiledSpriteComponent) {
          (_tableBackground as TiledSpriteComponent).size = size;
        } else if (_tableBackground is RectangleComponent) {
          (_tableBackground as RectangleComponent).size = size;
        }
      }

      if (_pendingGameState != null) {
        final state = _pendingGameState!;
        _pendingGameState = null;
        updateTableFromState(state);
      }
    }
  }

  Future<void> _loadTableBackground() async {
    if (!_isSizeReady ||
        _currentSize.x == 0 ||
        _currentSize.y == 0 ||
        _isLoadingBackground) {
      return;
    }

    _isLoadingBackground = true;

    try {
      // Eski arka planı kaldır (eğer varsa)
      if (_tableBackground != null && _tableBackground!.isMounted) {
        _tableBackground!.removeFromParent();
      }

      // Sprite yükleme işlemini await ile bekleyelim
      final tableSprite = await Sprite.load('table_felt.png');

      // Yüklenme sırasında size değişmiş olabilir, tekrar kontrol et
      if (!_isSizeReady || _currentSize.x == 0 || _currentSize.y == 0) {
        _isLoadingBackground = false;
        return;
      }

      // Sprite'ın orijinal boyutunu kullanarak tile pattern oluştur
      _tableBackground = TiledSpriteComponent(
        sprite: tableSprite,
        size: _currentSize,
        tileSize: tableSprite.originalSize,
        anchor: Anchor.topLeft,
      )..priority = -1;

      add(_tableBackground!);
    } catch (e) {
      try {
        final paperSprite = await Sprite.load('paper.png');

        // Yüklenme sırasında size değişmiş olabilir, tekrar kontrol et
        if (!_isSizeReady || _currentSize.x == 0 || _currentSize.y == 0) {
          _isLoadingBackground = false;
          return;
        }

        _tableBackground = TiledSpriteComponent(
          sprite: paperSprite,
          size: _currentSize,
          tileSize: paperSprite.originalSize,
          anchor: Anchor.topLeft,
        )..priority = -1;

        add(_tableBackground!);
      } catch (_) {
        // Fallback: Basit bir renkli dikdörtgen kullan
        if (_isSizeReady && _currentSize.x > 0 && _currentSize.y > 0) {
          _tableBackground = RectangleComponent(
            size: _currentSize,
            paint: Paint()..color = const Color(0xFF2D5016),
          )..priority = -1;
          add(_tableBackground!);
        }
      }
    } finally {
      _isLoadingBackground = false;
    }
  }

  void updateGameState(GameState gameState) {
    if (!_isSizeReady) {
      _pendingGameState = gameState;
      return;
    }
    updateTableFromState(gameState);
  }

  void updateTableFromState(GameState gameState) {
    if (!_isSizeReady || _currentSize.x == 0 || _currentSize.y == 0) {
      _pendingGameState = gameState;
      return;
    }

    final newCardIds = <String>{};

    if (gameState.currentMoodCard != null) {
      final moodCardId = 'mood-${gameState.currentMoodCard!.id}';
      newCardIds.add(moodCardId);

      if (!_activeCardIds.contains(moodCardId)) {
        final moodCard = FlameMoodCard(
          gameState.currentMoodCard!,
          position: Vector2(_currentSize.x / 2, _currentSize.y * 0.25),
        );
        add(moodCard);
        _activeCardIds.add(moodCardId);
      }
    }

    if (gameState.isRevealed) {
      final playerCount = gameState.playedCardIds.length;
      if (playerCount == 0) return;

      final double fanAngle = 1.2;
      final double startAngle = -(fanAngle / 2);
      final double angleStep = playerCount > 1
          ? fanAngle / (playerCount - 1)
          : 0;
      final double radius = _currentSize.y * 0.45;
      final fanCenter = Vector2(_currentSize.x / 2, _currentSize.y * 0.65);

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
    children
        .whereType<FlameMoodCard>()
        .where((card) => !newCardIds.contains('mood-${card.moodCard.id}'))
        .forEach((card) => card.removeFromParent());
    children
        .whereType<FlamePhotoCard>()
        .where(
          (card) => !newCardIds.contains('photo-${card.cardId}-${card.userId}'),
        )
        .forEach((card) => card.removeFromParent());
  }
}
