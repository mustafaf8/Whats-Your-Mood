import 'package:flutter/material.dart';
import '../../models/player_status.dart';

class PlayerAvatarWidget extends StatelessWidget {
  final PlayerStatus player;
  final bool isMe;
  final bool isCurrentTurn;
  final int? remainingSeconds;
  final int? totalTurnSeconds;

  const PlayerAvatarWidget({
    super.key,
    required this.player,
    this.isMe = false,
    this.isCurrentTurn = false,
    this.remainingSeconds,
    this.totalTurnSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: player.hasPlayed
              ? Colors.green.shade400
              : Colors.grey.shade200,
          width: player.hasPlayed ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: player.hasPlayed
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: player.hasPlayed ? 12 : 8,
            offset: const Offset(0, 3),
            spreadRadius: player.hasPlayed ? 1 : 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Timer progress indicator (sıra oyuncudaysa)
              if (isCurrentTurn &&
                  remainingSeconds != null &&
                  totalTurnSeconds != null &&
                  totalTurnSeconds! > 0)
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: remainingSeconds! / totalTurnSeconds!,
                    strokeWidth: 4,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      remainingSeconds! <= 10
                          ? Colors.red.shade400
                          : Colors.green.shade400,
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getAvatarColor(player.userId),
                      _getAvatarColor(player.userId).withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getAvatarColor(player.userId)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: isCurrentTurn
                      ? Border.all(
                          color: Colors.orange.shade400,
                          width: 3,
                        )
                      : null,
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.transparent,
                  child: Text(
                    player.username[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    player.hasPlayed
                        ? Icons.check_circle
                        : Icons.hourglass_empty,
                    color: player.hasPlayed
                        ? Colors.green.shade600
                        : Colors.grey.shade400,
                    size: 18,
                  ),
                ),
              ),
              // Sıra göstergesi
              if (isCurrentTurn)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade400,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            player.username,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
              color: isMe
                  ? const Color(0xFF1976D2)
                  : const Color(0xFF1A1A1A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (player.isHost)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Host',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String userId) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];
    return colors[userId.hashCode.abs() % colors.length];
  }
}

