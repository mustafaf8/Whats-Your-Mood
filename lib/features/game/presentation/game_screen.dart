import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whats_your_mood/core/constants/app_colors.dart';
import '../provider/game_provider.dart';
import 'widgets/mood_card_widget.dart';
import 'widgets/photo_card_widget.dart';
import 'widgets/drawer_menu.dart';
import 'package:whats_your_mood/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/mock_card_data.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  String? selectedPhotoId;

  Future<void> _playCard(String cardId, int currentRound) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    await ref
        .read(gameRepositoryProvider)
        .playCard(
          gameId: widget.gameId,
          round: currentRound,
          userId: userId,
          cardId: cardId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final asyncGame = ref.watch(gameStreamProvider(widget.gameId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: asyncGame.when(
          data: (game) =>
              Text('${l10n.round} ${game.currentRound}/${game.totalRounds}'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Hata'),
        ),
        backgroundColor: AppColors.gradientStart,
        foregroundColor: AppColors.white,
      ),
      drawer: const DrawerMenu(),
      body: asyncGame.when(
        data: (gameState) => gameState.currentMoodCard == null
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mood Card
                    MoodCardWidget(
                      text: gameState.currentMoodCard?.text ?? 'Mood',
                    ),
                    const SizedBox(height: 32),
                    // İçerik: Reveal değilse eldeki fan, reveal ise tüm oynananlar grid
                    Expanded(
                      flex: 3,
                      child: gameState.isRevealed
                          ? GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              children: gameState.playedCardIds.entries.map((
                                e,
                              ) {
                                final username =
                                    gameState.playersUsernames[e.key] ?? e.key;
                                final photoId = e.value;
                                final photo = findPhotoCardById(photoId);
                                if (photo == null) {
                                  return Card(
                                    child: Center(child: Text(username)),
                                  );
                                }
                                return Column(
                                  children: [
                                    Expanded(
                                      child: PhotoCardWidget(
                                        photoCard: photo,
                                        onTap: () {},
                                        isSelected: false,
                                        isRevealed: true,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      username,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                );
                              }).toList(),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final cards = gameState.currentPhotoCards;
                                final total = cards.length;
                                const double cardWidth = 140;
                                const double cardHeight = 180;
                                final double baseBottom =
                                    constraints.maxHeight * 0.06;
                                final double selectedLift =
                                    constraints.maxHeight * 0.22;
                                final double horizontalSpread =
                                    constraints.maxWidth * 0.12;
                                final indices = List<int>.generate(
                                  total,
                                  (i) => i,
                                );
                                return Stack(
                                  alignment: Alignment.center,
                                  children: indices.map((index) {
                                    final photoCard = cards[index];
                                    final isSelected =
                                        selectedPhotoId == photoCard.id;
                                    final double baseLeft =
                                        constraints.maxWidth / 2 +
                                        (index - (total / 2) + 0.5) *
                                            horizontalSpread -
                                        (cardWidth / 2);
                                    final double left = baseLeft;
                                    final double bottom = isSelected
                                        ? baseBottom + selectedLift
                                        : baseBottom;
                                    final double angle = isSelected
                                        ? 0
                                        : (index - (total / 2) + 0.5) * 0.15;
                                    return AnimatedPositioned(
                                      key: ValueKey(photoCard.id),
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      curve: Curves.easeInOut,
                                      left: left.clamp(
                                        0.0,
                                        constraints.maxWidth - cardWidth,
                                      ),
                                      bottom: bottom,
                                      width: cardWidth,
                                      height: cardHeight,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.easeInOut,
                                        transform: Matrix4.rotationZ(angle),
                                        transformAlignment:
                                            Alignment.bottomCenter,
                                        child: PhotoCardWidget(
                                          photoCard: photoCard,
                                          onTap: () {
                                            final String currentCardId =
                                                photoCard.id;
                                            final bool isAlreadySelected =
                                                selectedPhotoId ==
                                                currentCardId;
                                            if (isAlreadySelected) {
                                              _playCard(
                                                currentCardId,
                                                gameState.currentRound,
                                              );
                                            } else {
                                              setState(() {
                                                selectedPhotoId = currentCardId;
                                              });
                                            }
                                          },
                                          isSelected: isSelected,
                                          isRevealed: false,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Next Round Button (host ve reveal olduğunda)
                    Builder(
                      builder: (context) {
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        final isHost =
                            userId != null && userId == gameState.hostId;
                        if (!gameState.isRevealed || !isHost) {
                          return const SizedBox.shrink();
                        }
                        return ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              selectedPhotoId = null;
                            });
                            if (gameState.currentRound >=
                                gameState.totalRounds) {
                              _showGameFinishedDialog(context);
                              return;
                            }
                            await ref
                                .read(gameRepositoryProvider)
                                .hostNextRound(widget.gameId);
                          },
                          child: Text(
                            gameState.currentRound < gameState.totalRounds
                                ? l10n.nextRound
                                : l10n.finishGame,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
      ),
    );
  }

  void _showGameFinishedDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎉 ${l10n.gameCompleted}'),
        content: Text(l10n.gameCompletedDesc),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(l10n.playAgain),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: Text(l10n.homePage),
          ),
        ],
      ),
    );
  }
}
