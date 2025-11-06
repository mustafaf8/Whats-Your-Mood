import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flame/game.dart';
import 'package:whats_your_mood/core/constants/app_colors.dart';
import '../provider/game_provider.dart';
import '../models/game_state.dart';
import '../models/player_status.dart';
import 'widgets/photo_card_widget.dart';
import 'widgets/player_avatar_widget.dart';
import 'widgets/drawer_menu.dart';
import 'package:whats_your_mood/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../flame/card_table_game.dart';

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
  late final CardTableGame _game;
  bool _listenerInitialized = false;
  DateTime? _lastRoundEndTime;
  GameState? _lastGameState;

  @override
  void initState() {
    super.initState();
    _game = CardTableGame(widget.gameId);
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    super.dispose();
  }

  void _startTimer(DateTime? roundEndTime) {
    if (_lastRoundEndTime == roundEndTime) return;
    _lastRoundEndTime = roundEndTime;

    _roundTimer?.cancel();
    if (roundEndTime == null) {
      setState(() => _remainingSeconds = 0);
      return;
    }

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

      if (diff <= 0) {
        timer.cancel();
        _autoPlayCard();
      }
    });
  }

  Future<void> _autoPlayCard() async {
    if (!mounted) return;

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
    if (!mounted) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await ref
          .read(gameRepositoryProvider)
          .playCard(
            gameId: widget.gameId,
            round: currentRound,
            userId: userId,
            cardId: cardId,
          );
      if (mounted) {
        setState(() => selectedPhotoId = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kart oynanırken hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _initializeListener() {
    if (_listenerInitialized) return;
    _listenerInitialized = true;

    ref.listen(gameStreamProvider(widget.gameId), (previous, next) {
      next.whenData((gameState) {
        if (mounted) {
          _game.updateGameState(gameState);
        }
      });
    });
  }

  void _updateGameState(GameState gameState) {
    if (_lastGameState == gameState) return;
    _lastGameState = gameState;

    if (mounted) {
      _game.updateGameState(gameState);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncGame = ref.watch(gameStreamProvider(widget.gameId));
    final l10n = AppLocalizations.of(context)!;

    _initializeListener();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: asyncGame.when(
          data: (game) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.round} ${game.currentRound}/${game.totalRounds}'),
              if (game.status == 'playing' &&
                  !game.isRevealed &&
                  _remainingSeconds > 0)
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
          loading: () => const Text('Yükleniyor...'),
          error: (_, __) => const Text('Hata'),
        ),
        backgroundColor: AppColors.gradientStart,
        foregroundColor: AppColors.white,
      ),
      drawer: const DrawerMenu(),
      body: asyncGame.when(
        data: (gameState) {
          _updateGameState(gameState);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _startTimer(gameState.roundEndTime);
            }
          });

          if (gameState.currentMoodCard == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (gameState.currentPhotoCards.isEmpty && !gameState.isRevealed) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Kartlar yükleniyor...',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return _buildTableLayout(gameState, context);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Hata: $e',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(gameStreamProvider(widget.gameId));
                },
                child: const Text('Yeniden Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableLayout(GameState gameState, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final otherPlayers = gameState.players
        .where((p) => p.userId != userId)
        .toList();
    final me = gameState.players.firstWhere(
      (p) => p.userId == userId,
      orElse: () => const PlayerStatus(
        userId: 'me',
        username: 'Ben',
        hasPlayed: false,
        isHost: false,
      ),
    );

    return Column(
      children: [
        if (otherPlayers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: otherPlayers
                  .map(
                    (p) => AnimatedScale(
                      scale: p.hasPlayed ? 1.05 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: PlayerAvatarWidget(player: p),
                    ),
                  )
                  .toList(),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: GameWidget<CardTableGame>(game: _game),
              ),
            ),
          ),
        ),
        if (gameState.isRevealed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildHostRevealControls(gameState, l10n, context),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: _buildMyPlayerArea(me, gameState),
          ),
        ),
      ],
    );
  }

  Widget _buildMyPlayerArea(PlayerStatus me, GameState gameState) {
    if (gameState.currentPhotoCards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AnimatedScale(
              scale: me.hasPlayed ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: PlayerAvatarWidget(player: me, isMe: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${gameState.currentRound}/${gameState.totalRounds}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              if (index >= gameState.currentPhotoCards.length) {
                return const SizedBox.shrink();
              }

              final photoCard = gameState.currentPhotoCards[index];
              final bool isSelected = selectedPhotoId == photoCard.id;
              final bool canPlay =
                  !gameState.hasPlayed && !gameState.isRevealed;

              return SizedBox(
                width: 140,
                child: Hero(
                  tag: 'photo-${photoCard.id}',
                  child: PhotoCardWidget(
                    photoCard: photoCard,
                    onTap: canPlay
                        ? () {
                            final String currentCardId = photoCard.id;
                            final bool already =
                                selectedPhotoId == currentCardId;
                            if (already) {
                              _playCard(currentCardId, gameState.currentRound);
                            } else {
                              setState(() => selectedPhotoId = currentCardId);
                            }
                          }
                        : () {},
                    isSelected: isSelected,
                    isRevealed: false,
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: gameState.currentPhotoCards.length,
          ),
        ),
      ],
    );
  }

  Widget _buildHostRevealControls(
    GameState gameState,
    AppLocalizations l10n,
    BuildContext context,
  ) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isHost = currentUserId != null && currentUserId == gameState.hostId;

    if (!isHost) return const SizedBox.shrink();

    return ElevatedButton(
      onPressed: () async {
        setState(() {
          selectedPhotoId = null;
        });

        if (gameState.currentRound >= gameState.totalRounds) {
          _showGameFinishedDialog(context);
          return;
        }

        try {
          await ref.read(gameRepositoryProvider).hostNextRound(widget.gameId);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tur başlatılırken hata: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gradientStart,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        gameState.currentRound < gameState.totalRounds
            ? l10n.nextRound
            : l10n.finishGame,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showGameFinishedDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🎉'),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.gameCompleted)),
          ],
        ),
        content: Text(l10n.gameCompletedDesc),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(l10n.playAgain),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/lobby');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientStart,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.homePage),
          ),
        ],
      ),
    );
  }
}
