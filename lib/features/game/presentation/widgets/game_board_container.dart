import 'package:flutter/material.dart';

class GameBoardContainer extends StatelessWidget {
  const GameBoardContainer({
    super.key,
    required this.child,
    this.bottomOverlay,
  });

  final Widget child;
  final Widget? bottomOverlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: child,
          ),
          if (bottomOverlay != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: bottomOverlay,
              ),
            ),
        ],
      ),
    );
  }
}

