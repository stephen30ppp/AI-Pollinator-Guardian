import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo container
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '🐝',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Title
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        // Subtitle
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondaryColor.withOpacity(0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}