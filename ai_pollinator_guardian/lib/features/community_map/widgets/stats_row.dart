import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class StatsRow extends StatelessWidget {
  final int sightingsToday;
  final int speciesCount;
  final double radiusKm;

  const StatsRow({
    super.key,
    required this.sightingsToday,
    required this.speciesCount,
    required this.radiusKm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            value: sightingsToday.toString(),
            label: 'Sightings Today',
          ),
          _buildStatItem(
            value: speciesCount.toString(),
            label: 'Species',
          ),
          _buildStatItem(
            value: '${radiusKm.toStringAsFixed(0)}km',
            label: 'Radius',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primarySwatch,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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