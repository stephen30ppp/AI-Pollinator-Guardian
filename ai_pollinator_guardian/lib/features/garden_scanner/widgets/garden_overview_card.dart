import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GardenOverviewCard extends StatelessWidget {
  final Map<String, dynamic> garden;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelect;
  final bool isSelectable;
  final bool isSelected;

  const GardenOverviewCard({
    super.key,
    required this.garden,
    required this.onTap,
    this.onLongPress,
    this.onSelect,
    this.isSelectable = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
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

    final pollinatorScore = garden['pollinator_score'];
    final scorePercentage = pollinatorScore != null ? pollinatorScore['percentage'] : 0;
    final scoreCategory = pollinatorScore != null ? pollinatorScore['category'] : 'No Score';

    return Card(
      elevation: isSelected ? 4 : 2,
      color: isSelected ? Colors.blue[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected 
            ? BorderSide(color: Colors.blue[400]!, width: 2.0)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with small thumbnail image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: garden['photos'] != null && (garden['photos'] as List).isNotEmpty
                      ? Container(
                          height: 120, // Smaller height than detailed card
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage((garden['photos'] as List).first),
                              fit: BoxFit.cover,
                              colorFilter: isSelected
                                  ? ColorFilter.mode(
                                      Colors.blue.withOpacity(0.2),
                                      BlendMode.srcATop,
                                    )
                                  : null,
                            ),
                          ),
                        )
                      : Container(
                          height: 120,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(Icons.eco, size: 40, color: Colors.grey),
                        ),
                ),
                // Selection checkbox overlay
                if (isSelectable)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withOpacity(0.8),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onSelect,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                  size: 28,
                                )
                              : Icon(
                                  Icons.circle_outlined,
                                  color: Colors.grey[600],
                                  size: 28,
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Pollinator score indicator (small circular indicator)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: _getScoreColor(scorePercentage),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$scorePercentage%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(scorePercentage),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Garden name and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          garden['name'] ?? 'Unnamed Garden',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? Colors.blue[700]
                                : AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          createdAt,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scoreCategory,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _getScoreColor(scorePercentage),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right arrow indicator
                  if (!isSelectable)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return Colors.green[700]!;
    if (percentage >= 60) return Colors.green[500]!;
    if (percentage >= 40) return Colors.amber[700]!;
    if (percentage >= 20) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}