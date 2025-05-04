import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isFullWidth;
  final double? scale;
  final IconData? icon;

  const ActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.isFullWidth = true,
    this.scale = 1.0,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    
    final buttonStyle = isPrimary
        ? ElevatedButton.styleFrom(
            backgroundColor: isDisabled 
                ? Colors.grey[400] 
                : AppColors.primaryColor,
            foregroundColor: Colors.white,
            elevation: isPrimary ? 2 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: isFullWidth ? const Size(double.infinity, 50) : null,
          )
        : ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDisabled 
                    ? Colors.grey[400]! 
                    : AppColors.primaryColor,
                width: 1.5,
              ),
            ),
            minimumSize: isFullWidth ? const Size(double.infinity, 50) : null,
          );
    
    // Adding a scaling effect using Transform
    return Transform.scale(
      scale: scale ?? 1.0,
      child: icon != null 
          ? ElevatedButton.icon(
              onPressed: onPressed,
              style: buttonStyle,
              icon: Icon(icon),
              label: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: buttonStyle,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
    );
  }
}