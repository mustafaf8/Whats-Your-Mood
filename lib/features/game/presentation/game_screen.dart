import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../provider/game_provider.dart';
import '../models/game_state.dart';
import 'widgets/drawer_menu.dart';
import 'package:whats_your_mood/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../flame/card_table_game.dart';
import 'widgets/game_appbar_title.dart';
import 'widgets/game_finished_dialog.dart';
import 'widgets/game_body.dart';

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

  void _startTimer(DateTime? turnEndTime) {
    if (_lastRoundEndTime == turnEndTime) return;
    _lastRoundEndTime = turnEndTime;

    _roundTimer?.cancel();
    if (turnEndTime == null) {
      setState(() => _remainingSeconds = 0);
      return;
    }

    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final diff = turnEndTime.difference(now).inSeconds;

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

    // Sadece sıra o anki kullanıcıdaysa otomatik kart oyna
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId != gameState.currentPlayerTurnId) {
      return;
    }

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
        final errorMessage = e.toString().contains('Sıra sizde değil')
            ? 'Sıra sizde değil, lütfen bekleyin'
            : 'Kart oynanırken hata: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
    final theme = Theme.of(context);

    _initializeListener();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: asyncGame.when(
            data: (game) => GameAppBarTitle(
              roundText:
                  '${l10n.round} ${game.currentRound}/${game.totalRounds}',
              showTimer:
                  game.status == 'playing' &&
                  !game.isRevealed &&
                  game.currentPlayerTurnId != null &&
                  _remainingSeconds > 0,
              remainingSeconds: _remainingSeconds,
            ),
            loading: () => const Text('Yükleniyor…'),
            error: (_, __) => const Text('Hata'),
          ),
        ),
      ),
      drawer: const DrawerMenu(),
      body: SafeArea(
        child: asyncGame.when(
          data: (gameState) {
            _updateGameState(gameState);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _startTimer(gameState.turnEndTime);
              }
            });

            if (gameState.currentMoodCard == null) {
              return const _InlineLoader();
            }

            return GameBody(
              gameState: gameState,
              game: _game,
              remainingSeconds: _remainingSeconds,
              onPlayCard: _playCard,
              onSelectCard: (cardId) {
                setState(() => selectedPhotoId = cardId);
              },
              selectedPhotoId: selectedPhotoId,
              onNextRound: () async {
                setState(() => selectedPhotoId = null);
                try {
                  await ref
                      .read(gameRepositoryProvider)
                      .hostNextRound(widget.gameId);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tur başlatılırken hata: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              onFinish: () {
                setState(() => selectedPhotoId = null);
                showGameFinishedDialog(
                  context,
                  l10n,
                  onHome: () {
                    Navigator.of(context).pop();
                    context.go('/lobby');
                  },
                );
              },
            );
          },
          loading: () => const _InlineLoader(),
          error: (e, stack) => _InlineError(
            message: 'Hata: $e',
            onRetry: () => ref.invalidate(gameStreamProvider(widget.gameId)),
          ),
        ),
      ),
    );
  }
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Yeniden dene')),
        ],
      ),
    );
  }
}