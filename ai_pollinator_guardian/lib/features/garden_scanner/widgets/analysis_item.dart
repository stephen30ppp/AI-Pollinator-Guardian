import 'package:flutter/material.dart';

class AnalysisItem extends StatelessWidget {
  final String category;
  final String status;
  final String description;
  final bool isCompact;

  const AnalysisItem({
    super.key,
    required this.category,
    required this.status,
    required this.description,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case 'good':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'warning':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case 'bad':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        icon = Icons.info;
        color = Colors.blue;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isCompact ? 8.0 : 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isCompact ? 20 : 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: isCompact
              ? Text(
                  "$category: $description",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}