import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:whats_your_mood/core/constants/app_colors.dart';
import '../../models/player_status.dart';
import '../../models/game_state.dart';
import 'photo_card_widget.dart';
import 'player_avatar_widget.dart';

class MyPlayerArea extends StatelessWidget {
  const MyPlayerArea({
    super.key,
    required this.me,
    required this.gameState,
    required this.selectedPhotoId,
    required this.remainingSeconds,
    required this.onSelect,
    required this.onPlay,
  });

  final PlayerStatus me;
  final GameState gameState;
  final String? selectedPhotoId;
  final int remainingSeconds;
  final void Function(String cardId) onSelect;
  final void Function(String cardId) onPlay;

  @override
  Widget build(BuildContext context) {
    if (gameState.currentPhotoCards.isEmpty) {
      return const SizedBox.shrink();
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    final bool canPlay = !gameState.hasPlayed && !gameState.isRevealed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AnimatedScale(
              scale: me.hasPlayed ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: PlayerAvatarWidget(
                player: me,
                isMe: true,
                isCurrentTurn: me.userId == gameState.currentPlayerTurnId,
                remainingSeconds: me.userId == gameState.currentPlayerTurnId
                    ? remainingSeconds
                    : null,
                totalTurnSeconds: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    me.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gradientStart.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${gameState.currentRound}/${gameState.totalRounds}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.gradientStart,
                          ),
                        ),
                      ),
                      if (canPlay &&
                          me.userId == gameState.currentPlayerTurnId) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Sıra Sizde',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xFFEF6C00),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (gameState.currentPlayerTurnId != null &&
                          me.userId != gameState.currentPlayerTurnId &&
                          !gameState.isRevealed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.hourglass_empty,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Sıra Bekleniyor',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemBuilder: (context, index) {
              if (index >= gameState.currentPhotoCards.length) {
                return const SizedBox.shrink();
              }

              final photoCard = gameState.currentPhotoCards[index];
              final bool isSelected = selectedPhotoId == photoCard.id;
              final bool isMyTurn = userId == gameState.currentPlayerTurnId;
              final bool canPlayCard =
                  canPlay && isMyTurn && !gameState.isRevealed;

              return AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: SizedBox(
                  width: 150,
                  child: Hero(
                    tag: 'photo-${photoCard.id}',
                    child: PhotoCardWidget(
                      photoCard: photoCard,
                      onTap: canPlayCard
                          ? () {
                              final String currentCardId = photoCard.id;
                              final bool already =
                                  selectedPhotoId == currentCardId;
                              if (already) {
                                onPlay(currentCardId);
                              } else {
                                onSelect(currentCardId);
                              }
                            }
                          : () {},
                      isSelected: isSelected,
                      isRevealed: false,
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: gameState.currentPhotoCards.length,
          ),
        ),
      ],
    );
  }
}

