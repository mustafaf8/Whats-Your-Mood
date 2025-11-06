import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

/// Sprite'ı tile pattern olarak tekrarlayan component
class TiledSpriteComponent extends PositionComponent with HasPaint {
  final Sprite sprite;
  final Vector2 tileSize;

  TiledSpriteComponent({
    required this.sprite,
    required Vector2 size,
    Vector2? tileSize,
    Vector2? position,
    Anchor anchor = Anchor.topLeft,
  })  : tileSize = tileSize ?? sprite.originalSize,
        super(
          size: size,
          position: position ?? Vector2.zero(),
          anchor: anchor,
        );

  @override
  void render(ui.Canvas canvas) {
    if (size.x <= 0 || size.y <= 0 || tileSize.x <= 0 || tileSize.y <= 0) {
      return;
    }

    final tilesX = (size.x / tileSize.x).ceil();
    final tilesY = (size.y / tileSize.y).ceil();

    for (var y = 0; y < tilesY; y++) {
      for (var x = 0; x < tilesX; x++) {
        final destRect = ui.Rect.fromLTWH(
          x * tileSize.x,
          y * tileSize.y,
          tileSize.x,
          tileSize.y,
        );

        sprite.renderRect(
          canvas,
          destRect,
          overridePaint: paint,
        );
      }
    }
  }
}

