import 'package:flutter/material.dart';

class AppColors {
  // Primary app colors
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF4CAF50, // Primary color - Green from the prototypes
    <int, Color>{
      50: Color(0xFFE8F5E9),
      100: Color(0xFFC8E6C9),
      200: Color(0xFFA5D6A7),
      300: Color(0xFF81C784),
      400: Color(0xFF66BB6A),
      500: Color(0xFF4CAF50), // Primary color
      600: Color(0xFF43A047),
      700: Color(0xFF388E3C),
      800: Color(0xFF2E7D32),
      900: Color(0xFF1B5E20),
    },
  );

  // Other app colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color divider = Color(0xFFEEEEEE);
  
  // Feature-specific colors
  static const Color beeColor = Color(0xFFFFC107);
  static const Color butterflyColor = Color(0xFFFF5722);
  static const Color otherPollinatorColor = Color(0xFF9C27B0);
}