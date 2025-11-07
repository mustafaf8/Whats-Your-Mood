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
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.mainGradient),
        ),
        title: asyncGame.when(
          data: (game) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${l10n.round} ${game.currentRound}/${game.totalRounds}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              if (game.status == 'playing' &&
                  !game.isRevealed &&
                  _remainingSeconds > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _remainingSeconds <= 10
                          ? Colors.red.shade400
                          : Colors.orange.shade400,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_remainingSeconds <= 10
                                      ? Colors.red
                                      : Colors.orange)
                                  .withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          '${(_remainingSeconds / 60).floor()}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          loading: () => const Text(
            'Yükleniyor...',
            style: TextStyle(color: Colors.white),
          ),
          error: (_, __) =>
              const Text('Hata', style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.transparent,
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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: otherPlayers
                  .map(
                    (p) => AnimatedScale(
                      scale: p.hasPlayed ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      child: PlayerAvatarWidget(player: p),
                    ),
                  )
                  .toList(),
            ),
          ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: GameWidget<CardTableGame>(game: _game),
            ),
          ),
        ),
        if (gameState.isRevealed)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildHostRevealControls(gameState, l10n, context),
          ),
        SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
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
              child: PlayerAvatarWidget(player: me, isMe: true),
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
                      if (canPlay) ...[
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
                              Text(
                                'Kart Seç',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
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
                      onTap: canPlay
                          ? () {
                              final String currentCardId = photoCard.id;
                              final bool already =
                                  selectedPhotoId == currentCardId;
                              if (already) {
                                _playCard(
                                  currentCardId,
                                  gameState.currentRound,
                                );
                              } else {
                                setState(() => selectedPhotoId = currentCardId);
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

  Widget _buildHostRevealControls(
    GameState gameState,
    AppLocalizations l10n,
    BuildContext context,
  ) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isHost = currentUserId != null && currentUserId == gameState.hostId;

    if (!isHost) return const SizedBox.shrink();

    final isLastRound = gameState.currentRound >= gameState.totalRounds;

    return FilledButton.icon(
      onPressed: () async {
        setState(() {
          selectedPhotoId = null;
        });

        if (isLastRound) {
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      },
      style: FilledButton.styleFrom(
        backgroundColor: isLastRound
            ? Colors.green.shade600
            : AppColors.gradientStart,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ).copyWith(elevation: MaterialStateProperty.all(8)),
      icon: Icon(
        isLastRound ? Icons.celebration : Icons.arrow_forward,
        size: 24,
      ),
      label: Text(
        isLastRound ? l10n.finishGame : l10n.nextRound,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showGameFinishedDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                l10n.gameCompleted,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.gameCompletedDesc,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.playAgain),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/lobby');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.gradientStart,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.homePage),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
