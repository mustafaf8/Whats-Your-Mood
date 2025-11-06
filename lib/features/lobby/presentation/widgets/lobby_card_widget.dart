import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/lobby_info.dart';

class LobbyCardWidget extends StatelessWidget {
  final LobbyInfo lobby;
  final VoidCallback? onTap;

  const LobbyCardWidget({
    super.key,
    required this.lobby,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = lobby.isFull || onTap == null;
    final isFull = lobby.isFull;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isFull 
              ? Colors.grey[300]! 
              : AppColors.gradientStart.withOpacity(0.3),
          width: isFull ? 1 : 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isFull
                  ? [
                      Colors.grey[100]!,
                      Colors.grey[200]!,
                    ]
                  : [
                      Colors.white,
                      AppColors.gradientStart.withOpacity(0.05),
                    ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lobby.lobbyName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isFull ? Colors.grey[600] : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (lobby.hasPassword)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.gradientStart.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.lock,
                        size: 16,
                        color: AppColors.gradientStart,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lobby.hostUsername,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isFull
                      ? Colors.grey[300]
                      : AppColors.gradientStart.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFull ? Icons.group_off : Icons.group,
                      size: 16,
                      color: isFull 
                          ? Colors.grey[600] 
                          : AppColors.gradientStart,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${lobby.playerCount}/${lobby.maxPlayers}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isFull 
                            ? Colors.grey[600] 
                            : AppColors.gradientStart,
                      ),
                    ),
                  ],
                ),
              ),
              if (isFull) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Dolu',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
