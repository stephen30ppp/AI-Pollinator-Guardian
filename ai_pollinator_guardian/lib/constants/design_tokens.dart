import 'package:flutter/material.dart';
import 'app_colors.dart';

class DesignTokens {
  // Spacing values
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Default padding
  static const EdgeInsets defaultPadding = EdgeInsets.symmetric(horizontal: l, vertical: m);
  
  // Border radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusCircular = 100.0;
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Button sizes
  static const double buttonHeight = 50.0;
  static const double buttonHeightCompact = 40.0;
  
  // Text styles
  static TextStyle get titleLarge => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  static TextStyle get titleMedium => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 16,
    height: 1.5,
  );
  
  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 14,
    height: 1.5,
  );
  
  static TextStyle get labelMedium => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  // Material 3 Color Scheme (light mode)
  static ColorScheme get lightColorScheme => ColorScheme.fromSeed(
    seedColor: AppColors.primaryColor,
    brightness: Brightness.light,
  );
  
  // Material 3 Color Scheme (dark mode)
  static ColorScheme get darkColorScheme => ColorScheme.fromSeed(
    seedColor: AppColors.primaryColor,
    brightness: Brightness.dark,
  );
}