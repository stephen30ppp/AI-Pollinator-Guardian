import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import '../../../constants/design_tokens.dart';

class FactCardCarousel extends StatefulWidget {
  final List<PollinatorFact> facts;
  final String greeting;

  const FactCardCarousel({
    Key? key,
    required this.facts,
    this.greeting = 'Good Day, Nature Guardian!',
  }) : super(key: key);

  @override
  State<FactCardCarousel> createState() => _FactCardCarouselState();
}

class _FactCardCarouselState extends State<FactCardCarousel> {
  int _currentIndex = 0;
  bool _isExpanded = false;
  final SwiperController _swiperController = SwiperController();

  void _toggleExpand() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        // Make consistent height with feature cards (180px) when expanded
        height: _isExpanded ? 180 : 140,
        width: double.infinity, // Ensure full width
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.7),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bee icon
            Padding(
              padding: const EdgeInsets.all(DesignTokens.m),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                ),
                child: const Center(
                  child: Text('🐝', style: TextStyle(fontSize: 24)),
                ),
              ),
            ),

            // Content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: DesignTokens.m,
                  bottom: DesignTokens.m,
                  right: DesignTokens.m,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Greeting
                    Text(
                      widget.greeting,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.xs),

                    // Fact content
                    Expanded(
                      child: Swiper(
                        controller: _swiperController,
                        itemBuilder: (BuildContext context, int index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // The main fact text
                              Expanded(
                                child: Text(
                                  widget.facts[index].text,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.9),
                                    height: 1.4,
                                  ),
                                  maxLines: _isExpanded ? 5 : 2, // Adjusted for available space
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              
                              // Source attribution - always visible
                              Text(
                                'Source: ${widget.facts[index].source}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          );
                        },
                        itemCount: widget.facts.length,
                        onIndexChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        autoplay: !_isExpanded,
                        autoplayDelay: 8000,
                        curve: Curves.easeInOutCubic,
                        duration: 600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Expand/Collapse indicator
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.m, right: DesignTokens.m),
              child: AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.expand_more, // This will rotate to become expand_less
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
              ),
            )
          ],
        ),
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
          text: 'Bees can recognize human faces, and they have excellent memory skills, allowing them to return to rewarding flower patches.',
          source: 'Science Daily',
        ),
        const PollinatorFact(
          text: 'A single bee colony can pollinate up to 300 million flowers in a single day, playing a crucial role in our ecosystem.',
          source: 'National Geographic',
        ),
        const PollinatorFact(
          text: 'Monarch butterflies undertake an incredible migration, traveling over 3,000 miles each year from Canada/US to Mexico.',
          source: 'WWF',
        ),
        const PollinatorFact(
          text: 'Bats are vital nocturnal pollinators for over 500 plant species, including agave (for tequila!), mangoes, and bananas.',
          source: 'Bat Conservation Int.',
        ),
        const PollinatorFact(
          text: 'Some flowers use subtle electric fields to communicate with bees, helping them know if a flower has recently been visited.',
          source: 'PNAS Journal',
        ),
        const PollinatorFact(
          text: 'Hummingbirds, with their high metabolism, can visit up to 2,000 flowers in a single day seeking nectar.',
          source: 'Audubon Society',
        ),
      ];
}