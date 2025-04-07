import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';

class PollinatorBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const PollinatorBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Colors.white,
      elevation: 8.0,
      child: SizedBox(
        height: 56, // Reduced height to prevent overflow
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side of the bottom nav bar (Home, Identify)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(context, '🏠', 'Home', 0),
                  _buildNavItem(context, '📷', 'Identify', 1),
                ],
              ),
            ),
            
            // Empty space for the FAB (Map button)
            const SizedBox(width: 40),
            
            // Right side of the bottom nav bar (Garden, Chat)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(context, '🌼', 'Garden', 3),
                  _buildNavItem(context, '💬', 'Chat', 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String icon, String label, int index) {
    final bool isActive = selectedIndex == index;
    
    return InkWell(
      onTap: () => onItemSelected(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: 20, // Reduced size
                color: isActive ? AppColors.primaryColor : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 2), // Reduced spacing
            Text(
              label,
              style: TextStyle(
                fontSize: 10, // Reduced size
                color: isActive ? AppColors.primaryColor : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}