import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../constants/design_tokens.dart';

class FeatureCardCarousel extends StatefulWidget {
  final List<FeatureCardItem> items;
  
  const FeatureCardCarousel({
    Key? key,
    required this.items,
  }) : super(key: key);

  @override
  State<FeatureCardCarousel> createState() => _FeatureCardCarouselState();
}

class _FeatureCardCarouselState extends State<FeatureCardCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        SizedBox(
          height: 180, // Adjust height as needed
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return EnhancedFeatureCard(
                title: widget.items[index].title,
                description: widget.items[index].description,
                imagePath: widget.items[index].imagePath,
                onTap: widget.items[index].onTap,
              );
            },
          ),
        ),
        const SizedBox(height: DesignTokens.m),
        // Page indicator
        AnimatedSmoothIndicator(
          activeIndex: _currentPage,
          count: widget.items.length,
          effect: WormEffect(
            dotWidth: 8,
            dotHeight: 8,
            spacing: 8,
            radius: 4,
            dotColor: theme.colorScheme.surfaceVariant,
            activeDotColor: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class EnhancedFeatureCard extends StatefulWidget {
  final String title;
  final String description;
  final String imagePath;
  final VoidCallback onTap;

  const EnhancedFeatureCard({
    Key? key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.onTap,
  }) : super(key: key);

  @override
  State<EnhancedFeatureCard> createState() => _EnhancedFeatureCardState();
}

class _EnhancedFeatureCardState extends State<EnhancedFeatureCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s),
      child: Material(
        color: Colors.transparent,
        elevation: 4,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                image: DecorationImage(
                  image: AssetImage(widget.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
                padding: const EdgeInsets.all(DesignTokens.m),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.xs),
                    Text(
                      widget.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FeatureCardItem {
  final String title;
  final String description;
  final String imagePath;
  final VoidCallback onTap;

  FeatureCardItem({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.onTap,
  });
}