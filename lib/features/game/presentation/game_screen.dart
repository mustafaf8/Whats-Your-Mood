import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whats_your_mood/core/constants/app_colors.dart';
import '../provider/game_provider.dart';
import '../models/game_state.dart';
import '../models/player_status.dart';
import 'widgets/mood_card_widget.dart';
import 'widgets/photo_card_widget.dart';
import 'widgets/player_avatar_widget.dart';
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
  Timer? _roundTimer;
  int _remainingSeconds = 0;

  @override
  void dispose() {
    _roundTimer?.cancel();
    super.dispose();
  }

  void _startTimer(DateTime? roundEndTime) {
    _roundTimer?.cancel();
    if (roundEndTime == null) return;

    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final diff = roundEndTime.difference(now).inSeconds;

      setState(() {
        _remainingSeconds = diff > 0 ? diff : 0;
      });

      // Zaman doldu ve kart oynamadıysa otomatik oyna
      if (diff <= 0) {
        timer.cancel();
        _autoPlayCard();
      }
    });
  }

  Future<void> _autoPlayCard() async {
    final asyncGame = ref.read(gameStreamProvider(widget.gameId));
    if (!asyncGame.hasValue) return;

    final gameState = asyncGame.value!;
    if (gameState.hasPlayed) return;

    final cards = gameState.currentPhotoCards;
    if (cards.isEmpty) return;

    final randomCard = cards[Random().nextInt(cards.length)];
    await _playCard(randomCard.id, gameState.currentRound);
  }

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
          data: (game) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.round} ${game.currentRound}/${game.totalRounds}'),
              if (game.status == 'playing' && !game.isRevealed)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _remainingSeconds <= 10
                          ? Colors.red.shade300
                          : Colors.orange.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(_remainingSeconds / 60).floor()}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Hata'),
        ),
        backgroundColor: AppColors.gradientStart,
        foregroundColor: AppColors.white,
      ),
      drawer: const DrawerMenu(),
      body: asyncGame.when(
        data: (gameState) {
          // Zamanlayıcıyı başlat
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startTimer(gameState.roundEndTime);
          });

          if (gameState.currentMoodCard == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Masa düzeni için Stack kullan
          return _buildTableLayout(gameState, context);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
      ),
    );
  }

  Widget _buildTableLayout(GameState gameState, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final otherPlayers = gameState.players
        .where((p) => p.userId != userId)
        .toList();

    return Stack(
      children: [
        // Alt: Mevcut oyuncunun eli
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 250,
          child: gameState.isRevealed
              ? Center(
                  child: ElevatedButton(
                    onPressed: gameState.currentRound >= gameState.totalRounds
                        ? () => _showGameFinishedDialog(context)
                        : null,
                    child: const Text('Oyun Bitti'),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = gameState.currentPhotoCards;
                    final total = cards.length;
                    const double cardWidth = 140;
                    const double cardHeight = 180;
                    final double baseBottom = constraints.maxHeight * 0.06;
                    final double selectedLift = constraints.maxHeight * 0.22;
                    final double horizontalSpread = constraints.maxWidth * 0.12;
                    final indices = List<int>.generate(total, (i) => i);
                    return Stack(
                      alignment: Alignment.center,
                      children: indices.map((index) {
                        final photoCard = cards[index];
                        final isSelected = selectedPhotoId == photoCard.id;
                        final double baseLeft =
                            constraints.maxWidth / 2 +
                            (index - (total / 2) + 0.5) * horizontalSpread -
                            (cardWidth / 2);
                        final double bottom = isSelected
                            ? baseBottom + selectedLift
                            : baseBottom;
                        final double angle = isSelected
                            ? 0
                            : (index - (total / 2) + 0.5) * 0.15;
                        return AnimatedPositioned(
                          key: ValueKey(photoCard.id),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          left: baseLeft.clamp(
                            0.0,
                            constraints.maxWidth - cardWidth,
                          ),
                          bottom: bottom,
                          width: cardWidth,
                          height: cardHeight,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            transform: Matrix4.rotationZ(angle),
                            transformAlignment: Alignment.bottomCenter,
                            child: PhotoCardWidget(
                              photoCard: photoCard,
                              onTap: () {
                                if (gameState.hasPlayed) return;
                                final String currentCardId = photoCard.id;
                                final bool isAlreadySelected =
                                    selectedPhotoId == currentCardId;
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
        // Üst: Mood kartı veya Grid (ortalanmış)
        if (!gameState.isRevealed)
          Positioned.fill(
            top: 120,
            bottom: 270,
            child: Center(
              child: MoodCardWidget(
                text: gameState.currentMoodCard?.text ?? 'Mood',
              ),
            ),
          ),
        if (gameState.isRevealed)
          Positioned.fill(
            top: 120,
            bottom: 270,
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              padding: const EdgeInsets.all(20),
              children: gameState.playedCardIds.entries.map((e) {
                final username = gameState.playersUsernames[e.key] ?? e.key;
                final photoId = e.value;
                final photo = findPhotoCardById(photoId);
                if (photo == null) {
                  return Card(child: Center(child: Text(username)));
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
            ),
          ),
        // Oyuncu avatarları - Üstte kenarlar
        ..._buildPlayerPositions(otherPlayers, context),
        // Durum mesajı
        if (!gameState.isRevealed)
          Positioned(
            top: 70,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: gameState.hasPlayed
                    ? Colors.green.shade100
                    : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                gameState.hasPlayed
                    ? 'Kartınız oynandı! Diğer oyuncuları bekleyin...'
                    : 'Bir kart seçin ve oynayın',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        // Host butonu
        if (gameState.isRevealed)
          Builder(
            builder: (context) {
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              final isHost =
                  currentUserId != null && currentUserId == gameState.hostId;
              if (!isHost) return const SizedBox.shrink();
              return Positioned(
                bottom: 270,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      selectedPhotoId = null;
                    });
                    if (gameState.currentRound >= gameState.totalRounds) {
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
                ),
              );
            },
          ),
      ],
    );
  }

  List<Widget> _buildPlayerPositions(
    List<PlayerStatus> players,
    BuildContext context,
  ) {
    if (players.isEmpty) return [];
    final positions = <Widget>[];
    final total = players.length;

    if (total == 1) {
      // Tek oyuncu - sol üst
      positions.add(
        Positioned(
          top: 20,
          left: 20,
          child: PlayerAvatarWidget(player: players[0]),
        ),
      );
    } else if (total == 2) {
      // İki oyuncu - sol ve sağ üst
      positions.add(
        Positioned(
          top: 20,
          left: 20,
          child: PlayerAvatarWidget(player: players[0]),
        ),
      );
      positions.add(
        Positioned(
          top: 20,
          right: 20,
          child: PlayerAvatarWidget(player: players[1]),
        ),
      );
    } else if (total >= 3) {
      // 3+ oyuncu - sol, üst merkez, sağ
      positions.add(
        Positioned(
          top: 20,
          left: 20,
          child: PlayerAvatarWidget(player: players[0]),
        ),
      );
      positions.add(
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(child: PlayerAvatarWidget(player: players[1])),
        ),
      );
      positions.add(
        Positioned(
          top: 20,
          right: 20,
          child: PlayerAvatarWidget(player: players[2]),
        ),
      );
      // Ekstra oyuncular için sol taraf
      if (total > 3) {
        for (int i = 3; i < total; i++) {
          positions.add(
            Positioned(
              top: 120 + (i - 3) * 80,
              left: 20,
              child: PlayerAvatarWidget(player: players[i]),
            ),
          );
        }
      }
    }
    return positions;
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
