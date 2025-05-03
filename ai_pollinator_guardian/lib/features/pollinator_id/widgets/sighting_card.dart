import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sighting_image.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';

class SightingCard extends StatelessWidget {
  final Map<String, dynamic> sighting;
  final VoidCallback? onTap;

  const SightingCard({
    super.key,
    required this.sighting,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the image
            SightingImage(
              imageUrl: sighting['imageUrl'],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pollinator Name
                  Text(
                    sighting['pollinatorName'] ?? 'Unknown Pollinator',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Scientific Name
                  _buildInfoRow(
                    'Scientific Name:',
                    sighting['pollinatorId'] ?? 'N/A',
                  ),
                  const SizedBox(height: 4),
                  // Confidence
                  _buildInfoRow(
                    'Confidence:',
                    '${sighting['confidence']?.toStringAsFixed(2) ?? 'N/A'}%',
                  ),
                  const SizedBox(height: 4),
                  // Timestamp
                  _buildInfoRow(
                    'Date:',
                    _formatTimestamp(sighting['timestamp']),
                    textColor: Colors.grey,
                  ),
                  // Add more details as needed
                  if (sighting['location'] != null) 
                    _buildInfoRow(
                      'Location:',
                      sighting['location'],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      final DateTime date = (timestamp as Timestamp).toDate();
      // Format date as desired - could use intl package for more options
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}