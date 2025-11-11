import 'package:flutter/material.dart';
import '../../models/player_status.dart';
import 'player_avatar_widget.dart';

class OtherPlayersBar extends StatelessWidget {
  const OtherPlayersBar({
    super.key,
    required this.players,
    required this.currentTurnUserId,
    required this.remainingSeconds,
  });

  final List<PlayerStatus> players;
  final String? currentTurnUserId;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: players
            .map(
              (p) => AnimatedScale(
                scale: p.hasPlayed ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: PlayerAvatarWidget(
                  player: p,
                  isCurrentTurn: p.userId == currentTurnUserId,
                  remainingSeconds:
                      p.userId == currentTurnUserId ? remainingSeconds : null,
                  totalTurnSeconds: 30,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

