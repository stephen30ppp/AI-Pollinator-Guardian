import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/constants/design_tokens.dart';

class LegendCard extends StatelessWidget {
  final String title;
  final List<LegendItem> items;
  
  const LegendCard({
    super.key,
    required this.title,
    required this.items,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
      ),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: DesignTokens.s),
            ...items,
          ],
        ),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  
  const LegendItem({
    super.key,
    required this.color,
    required this.label,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label, 
            style: TextStyle(
              fontSize: 12, 
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}