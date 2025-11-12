import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whats_your_mood/l10n/app_localizations.dart';

import '../../flame/card_table_game.dart';
import '../../models/game_state.dart';
import '../../models/player_status.dart';
import 'host_reveal_button.dart';
import 'my_player_area.dart';
import 'other_players_bar.dart';

class GameBody extends ConsumerWidget {
  const GameBody({
    super.key,
    required this.gameState,
    required this.game,
    required this.remainingSeconds,
    required this.selectedPhotoId,
    required this.onSelectCard,
    required this.onPlayCard,
    required this.onNextRound,
    required this.onFinish,
  });

  final GameState gameState;
  final CardTableGame game;
  final int remainingSeconds;
  final String? selectedPhotoId;
  final void Function(String cardId) onSelectCard;
  final Future<void> Function(String cardId, int currentRound) onPlayCard;
  final VoidCallback onNextRound;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    final me = gameState.players.firstWhere(
      (player) => player.userId == userId,
      orElse: () => const PlayerStatus(
        userId: 'me',
        username: 'Ben',
        hasPlayed: false,
        isHost: false,
      ),
    );
    final otherPlayers =
        gameState.players.where((player) => player.userId != me.userId).toList();

    final bool isHost = userId != null && userId == gameState.hostId;
    final bool showHostControls = isHost && gameState.isRevealed;

    final PlayerStatus? currentTurnPlayer =
        _findPlayer(gameState.players, gameState.currentPlayerTurnId);
    final bool isMyTurn =
        currentTurnPlayer != null && currentTurnPlayer.userId == me.userId;
    final bool showTimer = !gameState.isRevealed && remainingSeconds > 0;
    final double progress =
        _roundProgress(gameState.currentRound, gameState.totalRounds);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 780;
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final double targetBoardHeight =
            (isCompact ? availableWidth * 0.75 : availableWidth * 0.5)
                .clamp(280.0, 520.0);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16 : 24,
            vertical: isCompact ? 16 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GameStatusCard(
                roundLabel:
                    '${l10n.round} ${gameState.currentRound}/${gameState.totalRounds}',
                playerCount: gameState.players.length,
                isRevealed: gameState.isRevealed,
                isMyTurn: isMyTurn,
                remainingSeconds: remainingSeconds,
                currentPlayerName: currentTurnPlayer?.username,
                progress: progress,
                showTimer: showTimer,
              ),
              if (gameState.currentMoodCard != null) ...[
                const SizedBox(height: 16),
                _MoodCard(text: gameState.currentMoodCard!.text),
              ],
              if (otherPlayers.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Oyuncular',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OtherPlayersBar(
                        players: otherPlayers,
                        currentTurnUserId: gameState.currentPlayerTurnId,
                        remainingSeconds: remainingSeconds,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _BoardCard(game: game, height: targetBoardHeight),
              const SizedBox(height: 20),
              _SectionCard(
                child: MyPlayerArea(
                  me: me,
                  gameState: gameState,
                  selectedPhotoId: selectedPhotoId,
                  remainingSeconds: remainingSeconds,
                  onSelect: onSelectCard,
                  onPlay: (cardId) => onPlayCard(cardId, gameState.currentRound),
                ),
              ),
              if (showHostControls) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Oyun akışı',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      HostRevealButton(
                        isHost: true,
                        isRevealed: gameState.isRevealed,
                        isLastRound:
                            gameState.currentRound >= gameState.totalRounds,
                        onNextRound: onNextRound,
                        onFinish: onFinish,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GameStatusCard extends StatelessWidget {
  const _GameStatusCard({
    required this.roundLabel,
    required this.playerCount,
    required this.isRevealed,
    required this.isMyTurn,
    required this.remainingSeconds,
    required this.currentPlayerName,
    required this.progress,
    required this.showTimer,
  });

  final String roundLabel;
  final int playerCount;
  final bool isRevealed;
  final bool isMyTurn;
  final int remainingSeconds;
  final String? currentPlayerName;
  final double progress;
  final bool showTimer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> pills = [
      _StatusPill(
        icon: Icons.flag_outlined,
        label: roundLabel,
        foreground: theme.colorScheme.primary,
        background: theme.colorScheme.primaryContainer,
      ),
      _StatusPill(
        icon: isRevealed ? Icons.visibility : Icons.visibility_off,
        label: isRevealed ? 'Kartlar açık' : 'Kartlar gizli',
        foreground: theme.colorScheme.secondary,
        background: theme.colorScheme.secondaryContainer,
      ),
      _StatusPill(
        icon: Icons.people_alt_outlined,
        label: '$playerCount oyuncu',
        foreground: theme.colorScheme.tertiary,
        background: theme.colorScheme.tertiaryContainer,
      ),
    ];

    if (showTimer && remainingSeconds > 0) {
      pills.add(
        _StatusPill(
          icon: Icons.timer_outlined,
          label: _formatSeconds(remainingSeconds),
          foreground: theme.colorScheme.error,
          background: theme.colorScheme.errorContainer,
        ),
      );
    }

    if (currentPlayerName != null && currentPlayerName!.isNotEmpty) {
      final String label =
          isMyTurn ? 'Sıra sende' : 'Sıradaki: $currentPlayerName';
      pills.add(
        _StatusPill(
          icon: Icons.touch_app_outlined,
          label: label,
          foreground:
              isMyTurn ? theme.colorScheme.primary : theme.colorScheme.outline,
          background: isMyTurn
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceVariant,
        ),
      );
    }

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Oyun durumu',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pills,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.emoji_emotions_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({required this.game, required this.height});

  final CardTableGame game;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surfaceVariant.withOpacity(0.45),
              theme.colorScheme.surfaceVariant.withOpacity(0.15),
            ],
          ),
        ),
        child: SizedBox(
          height: height,
          child: GameWidget<CardTableGame>(game: game),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.clipBehavior,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Clip? clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: clipBehavior ?? Clip.none,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

PlayerStatus? _findPlayer(List<PlayerStatus> players, String? userId) {
  if (userId == null) return null;
  for (final player in players) {
    if (player.userId == userId) {
      return player;
    }
  }
  return null;
}

double _roundProgress(int currentRound, int totalRounds) {
  if (totalRounds <= 0) {
    return 0;
  }
  final int safeRound = currentRound.clamp(0, totalRounds).toInt();
  return safeRound / totalRounds;
}

String _formatSeconds(int totalSeconds) {
  if (totalSeconds <= 0) {
    return '00:00';
  }
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  final String minutePart = minutes.toString().padLeft(2, '0');
  final String secondPart = seconds.toString().padLeft(2, '0');
  return '$minutePart:$secondPart';
}
