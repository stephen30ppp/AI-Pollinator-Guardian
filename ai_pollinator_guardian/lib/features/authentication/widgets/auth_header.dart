import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../constants/design_tokens.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  
  const AuthHeader({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo container with Lottie animation
        Center(
          child: Hero(
            tag: 'auth_logo',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                // Note: You'll need to add this Lottie file to your assets
                child: Lottie.asset(
                  'assets/animations/bee.json',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                  // Fallback to emoji if animation fails to load
                  errorBuilder: (context, error, stackTrace) => const Text(
                    '🐝',
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.xl),
        // Title
        Text(
          title,
          style: DesignTokens.titleLarge.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: DesignTokens.s),
        // Subtitle
        Text(
          subtitle,
          style: DesignTokens.bodyLarge.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: DesignTokens.xl),
      ],
    );
  }
}