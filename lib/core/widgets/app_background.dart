import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppBackground extends StatelessWidget {
  final Widget? child;

  const AppBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.lightGray,
      child: Stack(
        children: [
          // Dokulu arka plan (yüklenemezse sessizce gizlenir)
          Positioned.fill(
            child: Image.asset(
              'lib/assets/textures/paper.png',
              fit: BoxFit.none,
              repeat: ImageRepeat.repeat,
              filterQuality: FilterQuality.low,
              opacity: const AlwaysStoppedAnimation(0.25),
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          if (child != null) Positioned.fill(child: child!),
        ],
      ),
    );
  }
}


