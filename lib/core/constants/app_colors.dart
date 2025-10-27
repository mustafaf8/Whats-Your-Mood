import 'package:flutter/material.dart';

class AppColors {
  // Gradient Colors
  static const Color gradientStart = Color(0xFF00BFA5);
  static const Color gradientEnd = Color(0xFFFF6F00);

  // Accent Colors
  static const Color accentOrange = Color(0xFFFF6D00);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F5F5);

  // Linear Gradient
  static LinearGradient get mainGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientEnd],
  );
}
