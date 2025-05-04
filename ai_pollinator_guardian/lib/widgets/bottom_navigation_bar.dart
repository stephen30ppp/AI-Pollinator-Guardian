import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/utils/global.dart'; // 导入全局变量
import 'package:provider/provider.dart'; // 导入 Provider
import 'package:ai_pollinator_guardian/features/pollinator_id/providers/identify_provider.dart'; // 导入 IdentifyProvider
import 'package:ai_pollinator_guardian/features/garden_scanner/providers/garden_scanner_provider.dart'; // 导入 GardenScannerProvider

class PollinatorBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const PollinatorBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Get the bottom padding to account for system navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
            spreadRadius: 2,
          ),
        ],
      ),
      // Add bottom padding to ensure visibility above system navigation
      padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 8),
      child: SafeArea(
        // Only apply bottom safe area to avoid double padding
        top: false, 
        child: SizedBox(
          height: 54, // Slightly reduced height to move up
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(context, Icons.home_rounded, 'Home', 0),
              _buildNavItem(context, Icons.camera_alt_rounded, 'Identify', 1),
              _buildNavItem(context, Icons.map_rounded, 'Map', 2),
              _buildNavItem(context, Icons.local_florist_rounded, 'Garden', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final bool isActive = selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          // 按照_currentIdx是离开前的tab的逻辑，这里的selectedIndex就是当前要离开的tab
          final int _currentIdx = selectedIndex;
          final int newIdx = index;
          
          // 原来会重置Garden分析结果，现在注释掉这段代码，保留分析结果
          // if (_currentIdx == 3) context.read<GardenScannerProvider>().resetAnalysis();
          // 原来会重置识别结果，现在注释掉这段代码，保留识别结果
          // if (_currentIdx == 1) context.read<IdentifyProvider>().resetResult();

          onItemSelected(newIdx);
          currentTab.value = newIdx; // 更新全局选中索引
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use AnimatedContainer for smoother transitions
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isActive
                    ? AppColors.primaryColor
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.primaryColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}