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

    if (!_listenerInitialized) {
      _listenerInitialized = true;
      ref.listen(gameStreamProvider(widget.gameId), (previous, next) {
        next.whenData((gameState) {
          _game.updateGameState(gameState);
        });
      });
      asyncGame.whenData((gameState) {
        _game.updateGameState(gameState);
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
            child: GameWidget<CardTableGame>(game: _game),
          ),
        ),
        if (gameState.isRevealed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
              final photoCard = gameState.currentPhotoCards[index];
              final bool isSelected = selectedPhotoId == photoCard.id;
              return SizedBox(
                width: 140,
                child: Hero(
                  tag: 'photo-${photoCard.id}',
                  child: PhotoCardWidget(
                    photoCard: photoCard,
                    onTap: () {
                      if (gameState.hasPlayed) return;
                      final String currentCardId = photoCard.id;
                      final bool already = selectedPhotoId == currentCardId;
                      if (already) {
                        _playCard(currentCardId, gameState.currentRound);
                      } else {
                        setState(() => selectedPhotoId = currentCardId);
                      }
                    },
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
        await ref.read(gameRepositoryProvider).hostNextRound(widget.gameId);
      },
      child: Text(
        gameState.currentRound < gameState.totalRounds
            ? l10n.nextRound
            : l10n.finishGame,
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
