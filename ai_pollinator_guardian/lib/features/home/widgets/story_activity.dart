import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../constants/design_tokens.dart';

class StoryActivity extends StatelessWidget {
  final List<StoryItem> stories;
  final String title;
  final VoidCallback? onViewAll;

  const StoryActivity({
    Key? key,
    required this.stories,
    required this.title,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Header with title and "View all" button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s,
                      vertical: DesignTokens.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View all',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s),
        // Horizontal list of story items
        SizedBox(
          height: 110, // Fixed height for story items
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s),
            itemBuilder: (context, index) {
              return StoryActivityItem(story: stories[index]);
            },
          ),
        ),
      ],
    );
  }
}

class StoryActivityItem extends StatefulWidget {
  final StoryItem story;

  const StoryActivityItem({
    Key? key,
    required this.story,
  }) : super(key: key);

  @override
  State<StoryActivityItem> createState() => _StoryActivityItemState();
}

class _StoryActivityItemState extends State<StoryActivityItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: widget.story.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 80,
          margin: const EdgeInsets.only(right: DesignTokens.m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Story circle with gradient border
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surface,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: widget.story.imagePath.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: widget.story.imagePath,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: theme.colorScheme.surfaceVariant,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: theme.colorScheme.surfaceVariant,
                                child: const Icon(Icons.error_outline),
                              ),
                            )
                          : Image.asset(
                              widget.story.imagePath,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.xs),
              // Title
              Text(
                widget.story.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              // Date
              Text(
                widget.story.date,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StoryItem {
  final String title;
  final String date;
  final String imagePath;
  final VoidCallback onTap;
  final bool isViewed;

  StoryItem({
    required this.title,
    required this.date,
    required this.imagePath,
    required this.onTap,
    this.isViewed = false,
  });
}