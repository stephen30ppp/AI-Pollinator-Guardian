import 'package:flutter/material.dart';
import 'app_colors.dart'; // Assuming app_colors.dart is in the same directory

class DesignTokens {
  // -------------------
  // Spacing values
  // -------------------
  static const double xxxs = 2.0; // Extra extra extra small
  static const double xxs = 4.0;  // Extra extra small
  static const double xs = 8.0;   // Extra small
  static const double s = 12.0;  // Small (Commonly used, was missing)
  static const double m = 16.0;  // Medium (Base)
  static const double l = 24.0;   // Large
  static const double xl = 32.0;  // Extra Large
  static const double xxl = 48.0; // Extra Extra Large
  static const double xxxl = 64.0; // Extra Extra Extra Large

  // Specific use-case spacing (Use sparingly)
  static const double spaceBottom = 80.0; // For bottom scroll padding

  // Default padding
  static const EdgeInsets defaultPadding = EdgeInsets.symmetric(horizontal: m, vertical: s); // Adjusted default

  // -------------------
  // Border Radii
  // -------------------
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusCircular = 100.0; // For circular elements

  // -------------------
  // Border Widths
  // -------------------
  static const double borderWidthThin = 1.0;
  static const double borderWidth = 1.5;
  static const double borderWidthThick = 2.0;

  // -------------------
  // Animation Durations
  // -------------------
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800); // Added for slower fades/transitions

  // -------------------
  // Button / Element Heights
  // -------------------
  static const double buttonHeight = 50.0;
  static const double buttonHeightCompact = 40.0;
  static const double tapTarget = 48.0; // Minimum tap target size

  // -------------------
  // Text Styles (Adjust line heights and weights as needed for your design)
  // -------------------
  // Titles
  static TextStyle get displayLarge => const TextStyle(
    fontSize: 57, fontWeight: FontWeight.w400, height: 1.12, // ~Material 3 Display Large
  );
  static TextStyle get displayMedium => const TextStyle(
    fontSize: 45, fontWeight: FontWeight.w400, height: 1.15, // ~Material 3 Display Medium
  );
   static TextStyle get displaySmall => const TextStyle(
    fontSize: 36, fontWeight: FontWeight.w400, height: 1.22, // ~Material 3 Display Small
  );

  static TextStyle get headlineLarge => const TextStyle(
    fontSize: 32, fontWeight: FontWeight.w400, height: 1.25, // ~Material 3 Headline Large
  );
   static TextStyle get headlineMedium => const TextStyle(
    fontSize: 28, fontWeight: FontWeight.w400, height: 1.28, // ~Material 3 Headline Medium
  );
  static TextStyle get headlineSmall => const TextStyle(
    fontSize: 24, fontWeight: FontWeight.w400, height: 1.33, // ~Material 3 Headline Small
  );

  static TextStyle get titleLarge => const TextStyle(
    fontSize: 22, fontWeight: FontWeight.w500, height: 1.27, // ~Material 3 Title Large (Adjusted weight/size)
  );
  static TextStyle get titleMedium => const TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600, height: 1.30, // Kept custom definition (Slightly bolder/larger than M3)
  );
  static TextStyle get titleSmall => const TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, height: 1.35, // Added custom definition
  );

  // Body Text
  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400, height: 1.50, // ~Material 3 Body Large
  );
  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.42, // ~Material 3 Body Medium
  );
  static TextStyle get bodySmall => const TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, height: 1.33, // ~Material 3 Body Small
  );

  // Labels (Often used in buttons, captions, inputs)
   static TextStyle get labelLarge => const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w500, height: 1.42, // ~Material 3 Label Large
  );
  static TextStyle get labelMedium => const TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500, height: 1.33, // ~Material 3 Label Medium
  );
  static TextStyle get labelSmall => const TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500, height: 1.45, // ~Material 3 Label Small
  );

   // Caption (Added for very small text like image captions or tertiary info)
   static TextStyle get caption => const TextStyle(
     fontSize: 10, fontWeight: FontWeight.w400, height: 1.2, // Custom definition
   );


  // -------------------
  // Material 3 Color Schemes
  // -------------------
  static ColorScheme get lightColorScheme => ColorScheme.fromSeed(
    seedColor: AppColors.primaryColor, // Use your primary color
    brightness: Brightness.light,
    // Optional: Override specific colors if needed
    // primary: AppColors.primaryColor,
    // secondary: AppColors.accentColor,
    // background: AppColors.backgroundColor,
    // surface: Colors.white,
    // onPrimary: Colors.white,
    // onSecondary: Colors.black,
    // onBackground: AppColors.textPrimaryColor,
    // onSurface: AppColors.textPrimaryColor,
  );

  static ColorScheme get darkColorScheme => ColorScheme.fromSeed(
    seedColor: AppColors.primaryColor, // Use your primary color
    brightness: Brightness.dark,
    // Optional: Override specific colors for dark mode
    // secondary: AppColors.accentColor, // Might need adjustment for dark mode contrast
    // background: const Color(0xFF121212), // Common dark background
    // surface: const Color(0xFF1E1E1E), // Slightly lighter surface
  );
}