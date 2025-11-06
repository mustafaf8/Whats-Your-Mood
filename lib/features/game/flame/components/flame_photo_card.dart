import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class FlamePhotoCard extends PositionComponent with HasPaint {
  final String cardId;
  final String userId;
  final String username;
  late final TextComponent _emojiComponent;
  late final TextComponent _usernameComponent;

  FlamePhotoCard({
    required this.cardId,
    required this.userId,
    required this.username,
    required Vector2 position,
  }) : super(position: position, size: Vector2(140, 180));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    anchor = Anchor.center;
    
    final emojis = [
      '😄', '😂', '😍', '🤩', '😎', '🤔', '😜', '😇',
      '🤗', '🥳', '😴', '😱', '🤪', '😅', '🙃', '🫠',
      '🤓', '😈', '👻', '🎭',
    ];
    final emoji = emojis[cardId.hashCode.abs() % emojis.length];

    _emojiComponent = TextComponent(
      text: emoji,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 48),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.4),
    );
    add(_emojiComponent);

    _usernameComponent = TextComponent(
      text: username,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF000000),
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.85),
    );
    add(_usernameComponent);

    final startPosition = Vector2(position.x, -100);
    this.position = startPosition;

    add(
      MoveToEffect(
        position,
        EffectController(
          duration: 0.5,
          curve: Curves.easeOutQuad,
        ),
      ),
    );

    add(
      ScaleEffect.by(
        Vector2.all(0.1),
        EffectController(
          duration: 0.5,
          curve: Curves.easeOutQuad,
        ),
        onComplete: () {
          add(
            ScaleEffect.to(
              Vector2.all(1.05),
              EffectController(
                duration: 1.5,
                alternate: true,
                infinite: true,
              ),
            ),
          );
        },
      ),
    );

    add(
      OpacityEffect.to(
        1.0,
        EffectController(duration: 0.5),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final fillPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(16),
    );

    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, borderPaint);

    final shadowPaint = Paint()
      ..color = const Color(0x1A000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 2, size.x, size.y),
        const Radius.circular(16),
      ),
      shadowPaint,
    );

    super.render(canvas);
  }
}

