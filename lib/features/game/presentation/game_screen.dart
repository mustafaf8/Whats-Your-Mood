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
                    // Fan (Yelpaze) layout for photo cards
                    Expanded(
                      flex: 3,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cards = gameState.currentPhotoCards;
                          final total = cards.length;
                          final isRevealed = gameState.isRevealed;

                          // Visual tuning constants
                          const double cardWidth = 140;
                          const double cardHeight = 180;
                          final double baseBottom =
                              constraints.maxHeight * 0.06;
                          final double selectedLift =
                              constraints.maxHeight * 0.22; // lift increased
                          final double horizontalSpread =
                              constraints.maxWidth * 0.12;

                          // Build non-selected first, selected last so it appears on top
                          final indices = List<int>.generate(total, (i) => i);

                          return Stack(
                            alignment: Alignment.center,
                            children: indices.map((index) {
                              final photoCard = cards[index];
                              final isSelected =
                                  selectedPhotoId == photoCard.id;

                              // 4 farklı durum yönetimi
                              // Durum 1: Yelpaze (!isRevealed && !isSelected)
                              // Durum 2: Seçili/Kalkmış (!isRevealed && isSelected)
                              // Durum 3: Oynandı/Ortada (isRevealed && isSelected)
                              // Durum 4: Gizlendi (isRevealed && !isSelected)

                              double left;
                              double bottom;
                              double angle;
                              double opacity;

                              if (isRevealed && isSelected) {
                                // Durum 3: Ortada
                                left = (constraints.maxWidth - cardWidth) / 2;
                                bottom =
                                    constraints.maxHeight / 2 -
                                    (cardHeight / 2);
                                angle = 0;
                                opacity = 1.0;
                              } else if (isRevealed && !isSelected) {
                                // Durum 4: Gizli (ekran dışı)
                                left = (constraints.maxWidth - cardWidth) / 2;
                                bottom = -cardHeight;
                                angle = 0;
                                opacity = 0;
                              } else if (!isRevealed && isSelected) {
                                // Durum 2: Kalkmış
                                final double baseLeft =
                                    constraints.maxWidth / 2 +
                                    (index - (total / 2) + 0.5) *
                                        horizontalSpread -
                                    (cardWidth / 2);
                                left = baseLeft;
                                bottom = baseBottom + selectedLift;
                                angle = 0; // Seçilince açıyı sıfırla
                                opacity = 1.0;
                              } else {
                                // Durum 1: Yelpaze (varsayılan)
                                final double baseLeft =
                                    constraints.maxWidth / 2 +
                                    (index - (total / 2) + 0.5) *
                                        horizontalSpread -
                                    (cardWidth / 2);
                                left = baseLeft;
                                bottom = baseBottom;
                                angle = (index - (total / 2) + 0.5) * 0.15;
                                opacity = 1.0;
                              }

                              return AnimatedPositioned(
                                key: ValueKey(photoCard.id),
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                left: left.clamp(
                                  0.0,
                                  constraints.maxWidth - cardWidth,
                                ),
                                bottom: bottom,
                                width: cardWidth,
                                height: cardHeight,
                                child: AnimatedOpacity(
                                  opacity: opacity,
                                  duration: const Duration(milliseconds: 400),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                    transform: Matrix4.rotationZ(angle),
                                    transformAlignment: Alignment.bottomCenter,
                                    child: PhotoCardWidget(
                                      photoCard: photoCard,
                                      onTap: () {
                                        if (isRevealed) return;
                                        // Tur zaten bittiyse bir şey yapma

                                        final String currentCardId =
                                            photoCard.id;
                                        final bool isAlreadySelected =
                                            selectedPhotoId == currentCardId;

                                        if (isAlreadySelected) {
                                          _playCard(
                                            currentCardId,
                                            gameState.currentRound,
                                          );
                                        } else {
                                          // İLK TIKLAMA: KARTI SEÇ/KALDIR
                                          // Başka bir kart seçildi, sadece state'i güncelle (Durum 2'yi tetikle)
                                          setState(() {
                                            selectedPhotoId = currentCardId;
                                          });
                                        }
                                      },
                                      isSelected: isSelected,
                                      isRevealed: isRevealed,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Next Round Button
                    if (gameState.isRevealed)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedPhotoId = null;
                          });
                          if (gameState.currentRound >= gameState.totalRounds) {
                            // Oyun bitti dialog
                            _showGameFinishedDialog(context);
                          } else {
                            // Çok oyunculu akışta round ilerlemesi host tarafından yönetilecek
                          }
                        },
                        child: Text(
                          gameState.currentRound < gameState.totalRounds
                              ? l10n.nextRound
                              : l10n.finishGame,
                        ),
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
