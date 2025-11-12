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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
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

