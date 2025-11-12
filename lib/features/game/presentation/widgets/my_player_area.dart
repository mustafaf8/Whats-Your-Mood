import 'package:flutter/material.dart';
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

    final theme = Theme.of(context);
    final bool isMyTurn = me.userId == gameState.currentPlayerTurnId;
    final bool canPlay = !gameState.hasPlayed && !gameState.isRevealed;
    final bool canPlayCard = canPlay && isMyTurn;

    final Widget statusChip;
    if (canPlayCard) {
      statusChip = _StatusChip(
        label: 'Sıra sizde',
        icon: Icons.touch_app_outlined,
        color: theme.colorScheme.primary,
        background: theme.colorScheme.primaryContainer,
      );
    } else if (gameState.currentPlayerTurnId != null &&
        !isMyTurn &&
        !gameState.isRevealed) {
      statusChip = _StatusChip(
        label: 'Beklemede',
        icon: Icons.hourglass_bottom,
        color: theme.colorScheme.outline,
        background: theme.colorScheme.surfaceVariant,
      );
    } else {
      statusChip = const SizedBox.shrink();
    }

    final List<_StatusChip> infoPills = [
      _StatusChip(
        label: '${gameState.currentRound}/${gameState.totalRounds}',
        icon: Icons.flag_outlined,
        color: theme.colorScheme.secondary,
        background: theme.colorScheme.secondaryContainer,
      ),
      if (statusChip is! SizedBox) statusChip as _StatusChip,
    ];

    void handleCardTap(String cardId, bool isSelected) {
      if (!canPlayCard) return;
      if (isSelected) {
        onPlay(cardId);
      } else {
        onSelect(cardId);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PlayerAvatarWidget(
              player: me,
              isMe: true,
              isCurrentTurn: isMyTurn,
              remainingSeconds: isMyTurn ? remainingSeconds : null,
              totalTurnSeconds: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    me.username,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: infoPills),
                ],
              ),
            ),
            if (canPlayCard)
              FilledButton.icon(
                onPressed: selectedPhotoId == null
                    ? null
                    : () => onPlay(selectedPhotoId!),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Oyna'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: SizedBox(
            height: 186,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: gameState.currentPhotoCards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                if (index >= gameState.currentPhotoCards.length) {
                  return const SizedBox.shrink();
                }
                final photoCard = gameState.currentPhotoCards[index];
                final bool isSelected = selectedPhotoId == photoCard.id;
                final bool isDisabled = !canPlayCard;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 152,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: isSelected
                        ? Border.all(width: 2, color: theme.colorScheme.primary)
                        : null,
                  ),
                  child: Hero(
                    tag: 'photo-${photoCard.id}',
                    child: Opacity(
                      opacity: isDisabled ? 0.55 : 1,
                      child: PhotoCardWidget(
                        photoCard: photoCard,
                        onTap: () => handleCardTap(photoCard.id, isSelected),
                        isSelected: isSelected,
                        isRevealed: false,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (canPlayCard)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              selectedPhotoId == null
                  ? 'Kart seçerek oynayın.'
                  : 'Seçili kartı oynamak için tekrar dokunun veya "Oyna"ya basın.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
