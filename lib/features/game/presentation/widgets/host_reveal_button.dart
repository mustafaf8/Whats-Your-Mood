import 'package:flutter/material.dart';
import 'package:whats_your_mood/core/constants/app_colors.dart';

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

    final String label = isLastRound ? 'Bitir' : 'Sonraki Tur';
    final IconData icon =
        isLastRound ? Icons.flag_outlined : Icons.play_arrow_rounded;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: FilledButton.tonalIcon(
        key: ValueKey<bool>(isLastRound),
        onPressed: isLastRound ? onFinish : onNextRound,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          elevation: 6,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          foregroundColor: AppColors.gradientStart,
          shadowColor: AppColors.gradientStart.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

