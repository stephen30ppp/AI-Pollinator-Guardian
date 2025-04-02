import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class LegendItem {
  final String label;
  final Color color;
  final int count;

  LegendItem({
    required this.label,
    required this.color,
    required this.count,
  });
}

class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    // These would typically be passed as parameters or fetched from a service
    final items = [
      LegendItem(label: 'Bees', color: AppColors.beeColor, count: 18),
      LegendItem(label: 'Butterflies', color: AppColors.butterflyColor, count: 7),
      LegendItem(label: 'Other', color: AppColors.otherPollinatorColor, count: 3),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Pollinator Types',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => _buildLegendItem(item)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(LegendItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.label} (${item.count})',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}