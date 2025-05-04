import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/design_tokens.dart';

class ActivityStatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final VoidCallback? onTap;
  final String? heroTag;
  final int? target; // Target for progress indicator
  final bool showProgress; // Whether to show circular progress
  final bool isAddCard; // New property to indicate if this is an "Add Target" card

  const ActivityStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.heroTag,
    this.target,
    this.showProgress = false,
    this.isAddCard = false, // Default to false
  });

  // Factory constructor for creating Add Target card
  factory ActivityStatCard.addTarget({
    required String label,
    required VoidCallback onTap,
    String? heroTag,
  }) {
    return ActivityStatCard(
      label: label,
      value: 0,
      icon: Icons.add_circle_outline,
      onTap: onTap,
      heroTag: heroTag ?? 'add-target-$label',
      isAddCard: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool canTap = onTap != null;
    final bool displayProgress = showProgress && target != null && target! > 0;
    final double progressValue = displayProgress ? (value / target!).clamp(0.0, 1.0) : 0.0;

    // Handle the add card styling differently
    if (isAddCard) {
      return _buildAddTargetCard(context, colorScheme);
    }

    return Hero(
      tag: heroTag ?? 'stats-$label',
      child: Material(
        color: Colors.transparent,
        child: Card(
          color: canTap ? colorScheme.secondaryContainer : colorScheme.surfaceVariant.withOpacity(0.5),
          elevation: canTap ? 3 : 1,
          shadowColor: colorScheme.shadow.withOpacity(canTap ? 0.15 : 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          ),
          child: InkWell(
            onTap: canTap ? () {
              HapticFeedback.selectionClick();
              onTap!();
            } : null,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
            splashColor: canTap ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
            highlightColor: canTap ? colorScheme.primary.withOpacity(0.05) : Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.m),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top block – give every card exactly the same height
                  SizedBox(
                    height: 94, // Reduced slightly from 100 to accommodate the bottom section
                    width: double.infinity,
                    child: Center(
                      child: displayProgress
                          ? _buildProgressRing(colorScheme, progressValue, value, target!)
                          : _buildValueDisplay(colorScheme, value, icon),
                    ),
                  ),

                  // Label — always bottom-aligned inside a FIXED-HEIGHT box
                  SizedBox(
                    height: 42, // Reduced from 48 to fit within the card
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.bodyMedium.copyWith(
                          color: canTap
                              ? colorScheme.onSecondaryContainer.withOpacity(0.9)
                              : colorScheme.onSurfaceVariant.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddTargetCard(BuildContext context, ColorScheme colorScheme) {
    return Hero(
      tag: heroTag ?? 'add-target-$label',
      child: Material(
        color: Colors.transparent,
        child: Card(
          color: colorScheme.secondaryContainer.withOpacity(0.5),
          elevation: 1,
          shadowColor: colorScheme.shadow.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
            side: BorderSide(
              color: colorScheme.primary.withOpacity(0.3),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap?.call();
            },
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
            splashColor: colorScheme.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.m),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Same fixed block height as the other cards
                  SizedBox(
                    height: 94, // Reduced slightly to match regular card
                    width: double.infinity,
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_circle_outline,
                          color: colorScheme.primary,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  
                  // Label – fixed-height box keeps every card aligned
                  SizedBox(
                    height: 42, // Reduced from 48 to fit within the card
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.bodyMedium.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRing(ColorScheme colorScheme, double progressValue, int currentValue, int targetValue) {
    return Semantics(
      label: '$currentValue out of $targetValue $label',
      value: '${(progressValue * 100).round()}%',
      child: SizedBox(
        width: 90,
        height: 90,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progressValue),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOutCubic,
              builder: (context, animatedValue, _) {
                return CircularProgressIndicator(
                  value: animatedValue,
                  strokeWidth: 7,
                  backgroundColor: colorScheme.primary.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  strokeCap: StrokeCap.round,
                );
              }
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Counter for the main value
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: currentValue),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, _) {
                    return Text(
                      '$animatedValue',
                      style: DesignTokens.titleLarge.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontSize: 22, // Slightly reduced to prevent overflow
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                // Target value display
                Text(
                  '/ $targetValue',
                  style: DesignTokens.bodySmall.copyWith(
                    color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueDisplay(ColorScheme colorScheme, int displayValue, IconData displayIcon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon without gradient - simpler look
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            displayIcon,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: DesignTokens.xxs), // Further reduced spacing

        // Animated counter for the value
        Semantics(
          label: 'You have $displayValue $label',
          child: TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: displayValue),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return Text(
                '$animatedValue',
                style: DesignTokens.titleLarge.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 22, // Slightly reduced to prevent overflow
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}