import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whats_your_mood/core/constants/app_colors.dart';
import '../provider/game_provider.dart';
import 'widgets/mood_card_widget.dart';
import 'widgets/photo_card_widget.dart';
import 'widgets/drawer_menu.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  String? selectedPhotoId;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text('Tur ${gameState.currentRound}/${gameState.totalRounds}'),
        backgroundColor: AppColors.gradientStart,
        foregroundColor: AppColors.white,
      ),
      drawer: const DrawerMenu(),
      body: gameState.currentMoodCard == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mood Card
                  MoodCardWidget(text: gameState.currentMoodCard!.text),
                  const SizedBox(height: 32),
                  // Photo Cards Grid
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                      itemCount: gameState.currentPhotoCards.length,
                      itemBuilder: (context, index) {
                        final photoCard = gameState.currentPhotoCards[index];
                        final isSelected = selectedPhotoId == photoCard.id;
                        final isRevealed = gameState.isRevealed;

                        return PhotoCardWidget(
                          photoCard: photoCard,
                          onTap: () {
                            if (!isRevealed) {
                              setState(() {
                                selectedPhotoId = photoCard.id;
                              });
                              ref
                                  .read(gameProvider.notifier)
                                  .selectPhoto(photoCard);
                            }
                          },
                          isSelected: isSelected,
                          isRevealed: isRevealed,
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
                        if (gameState.currentRound < gameState.totalRounds) {
                          ref.read(gameProvider.notifier).nextRound();
                        } else {
                          // Oyun bitti dialog
                          _showGameFinishedDialog(context);
                        }
                      },
                      child: Text(
                        gameState.currentRound < gameState.totalRounds
                            ? 'Sonraki Tur'
                            : 'Oyunu Bitir',
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  void _showGameFinishedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Oyun Tamamlandı!'),
        content: const Text('Tüm turlar bitti. Tebrikler!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(gameProvider.notifier).resetGame();
            },
            child: const Text('Yeniden Oyna'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('Ana Sayfa'),
          ),
        ],
      ),
    );
  }
}
