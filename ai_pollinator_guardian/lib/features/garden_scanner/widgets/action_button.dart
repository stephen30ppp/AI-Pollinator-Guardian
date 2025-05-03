import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isFullWidth;

  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.primaryColor : Colors.grey[200],
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isPrimary ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}