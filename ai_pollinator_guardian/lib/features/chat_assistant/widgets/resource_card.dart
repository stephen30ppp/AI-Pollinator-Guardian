import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class ResourceCard extends StatelessWidget {
  final String title;
  final String content;
  final String? linkUrl;

  const ResourceCard({
    super.key,
    required this.title,
    required this.content,
    this.linkUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            if (linkUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GestureDetector(
                  onTap: () {
                    // Handle link tap - would typically launch URL
                  },
                  child: const Row(
                    children: [
                      Text(
                        'View Guide',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primarySwatch,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: AppColors.primarySwatch,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}