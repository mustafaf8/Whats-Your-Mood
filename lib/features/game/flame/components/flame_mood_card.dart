import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../models/mood_card.dart';

class FlameMoodCard extends PositionComponent with HasPaint {
  final MoodCard moodCard;
  late final TextComponent _textComponent;

  FlameMoodCard(this.moodCard, {required Vector2 position}) : super(position: position, size: Vector2(300, 150));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    anchor = Anchor.center;
    
    _textComponent = TextComponent(
      text: moodCard.text,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF6F00),
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );
    add(_textComponent);

    final emojiComponent = TextComponent(
      text: '🎯',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 40),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.3),
    );
    add(emojiComponent);

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
      const Radius.circular(20),
    );

    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, borderPaint);

    super.render(canvas);
  }
}

