import 'package:flutter/material.dart';
import 'package:whats_your_mood/core/constants/app_colors.dart';

class MoodCardWidget extends StatelessWidget {
  final String text;

  const MoodCardWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.accentOrange,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
