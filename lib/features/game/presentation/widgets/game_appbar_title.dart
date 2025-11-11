import 'package:flutter/material.dart';

class GameAppBarTitle extends StatelessWidget {
  const GameAppBarTitle({
    super.key,
    required this.roundText,
    required this.showTimer,
    required this.remainingSeconds,
  });

  final String roundText;
  final bool showTimer;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            roundText,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        if (showTimer)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: remainingSeconds <= 10
                    ? Colors.red.shade400
                    : Colors.orange.shade400,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (remainingSeconds <= 10 ? Colors.red : Colors.orange)
                        .withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    '${(remainingSeconds / 60).floor()}:${(remainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

