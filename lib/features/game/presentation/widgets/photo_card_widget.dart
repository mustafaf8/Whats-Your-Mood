import 'package:flutter/material.dart';
import 'package:whats_your_mood/core/constants/app_colors.dart';
import '../../models/photo_card.dart';

class PhotoCardWidget extends StatelessWidget {
  final PhotoCard photoCard;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isRevealed;

  const PhotoCardWidget({
    super.key,
    required this.photoCard,
    required this.onTap,
    this.isSelected = false,
    this.isRevealed = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentOrange : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentOrange : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentOrange.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Placeholder image
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📸', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(
                        photoCard.id,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              // Selection overlay
              if (isSelected || (isRevealed && isSelected))
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              // Selected icon
              if (isSelected)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.white,
                    size: 30,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
