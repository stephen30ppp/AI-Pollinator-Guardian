import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/widgets/score_ring.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/widgets/analysis_item.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/widgets/plant_item.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/widgets/action_item.dart';

class GardenCard extends StatelessWidget {
  final Map<String, dynamic> garden;

  const GardenCard({
    super.key,
    required this.garden,
  });

  @override
  Widget build(BuildContext context) {
    final pollinatorScore = garden['pollinator_score'];
    final analysis = garden['analysis'] as List;
    final recommendedPlants = garden['recommended_plants'] as List;
    final actionPlan = garden['action_plan'] as List;
    String createdAt = 'Unknown Date';

    if (garden['createdAt'] != null) {
      try {
        // Handle both string dates and Timestamps
        if (garden['createdAt'] is String) {
          createdAt = _formatDate(DateTime.parse(garden['createdAt']));
        } else {
          // Assuming Timestamp has toDate() method
          createdAt = _formatDate(garden['createdAt'].toDate());
        }
      } catch (e) {
        debugPrint('Error parsing createdAt: $e');
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with photo
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: garden['photos'] != null && (garden['photos'] as List).isNotEmpty
                ? Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage((garden['photos'] as List).first),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.photo, size: 60, color: Colors.grey),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Garden Name and Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      garden['name'] ?? 'Unnamed Garden',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Text(
                      createdAt,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Pollinator Score
                if (pollinatorScore != null)
                  Row(
                    children: [
                      ScoreRing(percentage: pollinatorScore['percentage']),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pollinatorScore['category'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              pollinatorScore['description'],
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                // Analysis Section
                const Text(
                  'Analysis:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...analysis.map((item) {
                  return AnalysisItem(
                    category: item['category'] as String,
                    status: item['status'] as String,
                    description: item['description'] as String,
                    isCompact: true,
                  );
                }),
                const SizedBox(height: 16),
                // Recommended Plants Section
                const Text(
                  'Recommended Plants:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...recommendedPlants.map((plant) {
                  return PlantItem(
                    name: plant['name'] as String,
                    description: plant['description'] as String,
                    tags: List<String>.from(plant['tags']),
                    isCompact: true,
                  );
                }),
                const SizedBox(height: 16),
                // Action Plan Section
                const Text(
                  'Action Plan:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...actionPlan.map((action) {
                  return ActionItem(
                    title: action['title'] as String,
                    progress: action['progress'] as int,
                    isCompact: true,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}