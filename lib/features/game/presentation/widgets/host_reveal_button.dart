import 'package:flutter/material.dart';

class HostRevealButton extends StatelessWidget {
  const HostRevealButton({
    super.key,
    required this.isHost,
    required this.isRevealed,
    required this.isLastRound,
    required this.onNextRound,
    required this.onFinish,
  });

  final bool isHost;
  final bool isRevealed;
  final bool isLastRound;
  final VoidCallback onNextRound;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    if (!isHost || !isRevealed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final String label = isLastRound ? 'Bitir' : 'Sonraki Tur';
    final IconData icon =
        isLastRound ? Icons.flag_outlined : Icons.play_arrow_rounded;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: FilledButton.icon(
        key: ValueKey<bool>(isLastRound),
        onPressed: isLastRound ? onFinish : onNextRound,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

