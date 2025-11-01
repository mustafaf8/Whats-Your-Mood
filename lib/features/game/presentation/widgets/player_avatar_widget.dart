import 'package:flutter/material.dart';
import '../../models/player_status.dart';

class PlayerAvatarWidget extends StatelessWidget {
  final PlayerStatus player;
  final bool isMe;

  const PlayerAvatarWidget({
    super.key,
    required this.player,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: player.hasPlayed ? Colors.green : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _getAvatarColor(player.userId),
                child: Text(
                  player.username[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (player.hasPlayed)
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                )
              else
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: Icon(
                    Icons.hourglass_empty,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            player.username,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              color: isMe ? Colors.blue : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (player.isHost)
            Text(
              'Host',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
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

