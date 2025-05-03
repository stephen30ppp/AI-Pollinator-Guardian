import 'dart:io';
import 'package:flutter/material.dart';

class PastIdentificationItem extends StatelessWidget {
  final File image;
  final Map<String, dynamic> result;
  final DateTime timestamp;
  final VoidCallback onTap;
  
  const PastIdentificationItem({
    super.key,
    required this.image,
    required this.result,
    required this.timestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Extract pollinator name from identification result
    final name = result['identification']['commonName'] ?? 'Unknown';
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                image,
                width: 110,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    // Simple formatting - can be enhanced with intl package
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}