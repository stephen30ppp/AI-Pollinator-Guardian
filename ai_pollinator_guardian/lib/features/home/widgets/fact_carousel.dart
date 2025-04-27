import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import '../../../constants/design_tokens.dart';

class FactCardCarousel extends StatefulWidget {
  final List<PollinatorFact> facts;
  final VoidCallback? onActionTap;
  final String actionLabel;
  final String greeting;

  const FactCardCarousel({
    Key? key,
    required this.facts,
    this.onActionTap,
    this.actionLabel = 'Log a sighting',
    this.greeting = 'Good Day, Nature Guardian!',
  }) : super(key: key);

  @override
  State<FactCardCarousel> createState() => _FactCardCarouselState();
}

class _FactCardCarouselState extends State<FactCardCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Row(
        children: [
          // Bee icon or avatar
          Padding(
            padding: const EdgeInsets.all(DesignTokens.m),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🐝', style: TextStyle(fontSize: 24)),
              ),
            ),
          ),
          
          // Content area with greeting, fact swiper, and action button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Greeting
                Text(
                  widget.greeting,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                
                // Fact swiper
                SizedBox(
                  height: 40,
                  child: Swiper(
                    itemBuilder: (BuildContext context, int index) {
                      return Text(
                        widget.facts[index].text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    itemCount: widget.facts.length,
                    onIndexChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    autoplay: true,
                    autoplayDelay: 8000,
                    curve: Curves.easeInOutCubic,
                    duration: 600,
                  ),
                ),
                
                // Attribution
                Text(
                  'Source: ${widget.facts[_currentIndex].source}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // Action button
          if (widget.onActionTap != null)
            Padding(
              padding: const EdgeInsets.all(DesignTokens.m),
              child: Align(
                alignment: Alignment.bottomRight,
                child: FilledButton.tonal(
                  onPressed: widget.onActionTap,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.m,
                      vertical: DesignTokens.xs,
                    ),
                    textStyle: theme.textTheme.labelSmall,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 14),
                      const SizedBox(width: 4),
                      Text(widget.actionLabel),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PollinatorFact {
  final String text;
  final String source;
  
  const PollinatorFact({
    required this.text,
    required this.source,
  });
  
  // Sample facts about pollinators
  static List<PollinatorFact> get sampleFacts => [
    const PollinatorFact(
      text: 'Bees can recognize human faces, and they have excellent memory skills.',
      source: 'Science Daily',
    ),
    const PollinatorFact(
      text: 'A single bee colony can pollinate up to 300 million flowers in a single day.',
      source: 'National Geographic',
    ),
    const PollinatorFact(
      text: 'Monarch butterflies migrate over 3,000 miles each year.',
      source: 'WWF',
    ),
    const PollinatorFact(
      text: 'Bats pollinate over 500 plant species, including mangoes and bananas.',
      source: 'Bat Conservation International',
    ),
    const PollinatorFact(
      text: 'Some flowers use electric fields to communicate with bees.',
      source: 'PNAS Journal',
    ),
    const PollinatorFact(
      text: 'Hummingbirds can visit up to 2,000 flowers in a single day.',
      source: 'Audubon Society',
    ),
  ];
}