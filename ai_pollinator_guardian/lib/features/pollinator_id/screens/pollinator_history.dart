import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/services/sighting_service.dart';
import 'package:ai_pollinator_guardian/features/pollinator_id/widgets/sighting_card.dart';
import 'package:ai_pollinator_guardian/features/pollinator_id/widgets/empty_sightings_view.dart';

class PollinatorHistory extends StatelessWidget {
  final String userId;
  final SightingService _sightingService = SightingService();

  PollinatorHistory({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Identification History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(context),
            tooltip: 'Filter sightings',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _sightingService.getUserSightings(userId),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            );
          }
          
          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Force refresh
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          // Empty state
          final sightings = snapshot.data?.docs ?? [];
          if (sightings.isEmpty) {
            return EmptySightingsView(
              onAddSighting: () => Navigator.of(context).pushNamed('/identify'),
            );
          }

          // Content state - List of sightings
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: sightings.length,
            itemBuilder: (context, index) {
              final sighting = sightings[index].data() as Map<String, dynamic>;
              final sightingId = sightings[index].id;
              
              return SightingCard(
                sighting: sighting,
                onTap: () => _showSightingDetails(context, sightingId, sighting),
              );
            },
          );
        },
      ),
      // Optional: Add a floating action button to identify new pollinators
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
        onPressed: () => Navigator.of(context).pushNamed('/identify'),
      ),
    );
  }

  void _showSightingDetails(BuildContext context, String sightingId, Map<String, dynamic> sighting) {
    // Navigate to a detail page or show a dialog with more information
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildDetailSheet(context, sightingId, sighting),
    );
  }

  Widget _buildDetailSheet(BuildContext context, String sightingId, Map<String, dynamic> sighting) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            sighting['pollinatorName'] ?? 'Unknown Pollinator',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display photo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: sighting['imageUrl'] != null
                        ? Image.network(
                            sighting['imageUrl'],
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.error_outline, size: 48),
                                ),
                              );
                            },
                          )
                        : Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 48),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Display season indicator
                  _buildSeasonIndicator(sighting),
                  const SizedBox(height: 20),
                  
                  // Basic information
                  _buildSection(
                    title: 'Basic Information',
                    children: [
                      _buildInfoItem('Scientific Name', sighting['pollinatorId'] ?? 'N/A'),
                      _buildInfoItem('Type', sighting['pollinatorType'] ?? 'N/A'),
                      _buildInfoItem('Identification Confidence', '${sighting['confidence']?.toStringAsFixed(2) ?? 'N/A'}%'),
                      _buildInfoItem('Observation Date', _formatTimestamp(sighting['timestamp'])),
                      if (sighting['location'] != null)
                        _buildInfoItem('Observation Location', sighting['location']),
                    ],
                  ),
                  
                  // Detailed description
                  if (sighting['details'] != null && sighting['details'] is Map)
                    _buildSection(
                      title: 'Detailed Description',
                      children: [
                        if ((sighting['details'] as Map)['description'] != null)
                          _buildInfoItem('Description', (sighting['details'] as Map)['description']),
                        if ((sighting['details'] as Map)['status'] != null)
                          _buildInfoItem('Conservation Status', (sighting['details'] as Map)['status']),
                        if ((sighting['details'] as Map)['habitat'] != null)
                          _buildInfoItem('Habitat', (sighting['details'] as Map)['habitat']),
                      ],
                    ),
                  
                  // Plant preferences
                  if (sighting['plantPreferences'] != null && sighting['plantPreferences'] is Map)
                    _buildSection(
                      title: 'Plant Preferences',
                      children: [
                        if ((sighting['plantPreferences'] as Map)['season'] != null)
                          _buildInfoItem('Preferred Season', (sighting['plantPreferences'] as Map)['season']),
                        if ((sighting['plantPreferences'] as Map)['preferred'] != null)
                          _buildInfoItem(
                            'Preferred Plants',
                            (sighting['plantPreferences'] as Map)['preferred'] is List
                                ? (sighting['plantPreferences'] as Map)['preferred'].join(', ')
                                : 'N/A',
                          ),
                      ],
                    ),
                  
                  // Conservation impact
                  if (sighting['conservationImpact'] != null && sighting['conservationImpact'] is Map)
                    _buildSection(
                      title: 'Conservation Impact',
                      children: [
                        if ((sighting['conservationImpact'] as Map)['localSightings'] != null)
                          _buildInfoItem('Local Sightings Count', (sighting['conservationImpact'] as Map)['localSightings'].toString()),
                        if ((sighting['conservationImpact'] as Map)['importance'] != null)
                          _buildInfoItem('Ecological Importance', (sighting['conservationImpact'] as Map)['importance']),
                        if ((sighting['conservationImpact'] as Map)['tips'] != null)
                          _buildInfoItem('Conservation Tips', (sighting['conservationImpact'] as Map)['tips']),
                      ],
                    ),
                    
                  // New addition: Ecosystem Role
                  _buildSection(
                    title: 'Ecosystem Role',
                    children: [
                      _buildInfoItem('Pollination Efficiency', _getPollinationEfficiency(sighting)),
                      _buildInfoItem('Pollination Range', _getPollinationRange(sighting)),
                      _buildInfoItem('Ecological Chain Impact', 'As a pollination medium, plays a crucial role in local plant reproduction and maintaining biodiversity'),
                    ],
                  ),
                  
                  // New addition: Behavior Patterns
                  _buildSection(
                    title: 'Behavior Patterns',
                    children: [
                      _buildInfoItem('Activity Time', _getActivityTime(sighting)),
                      _buildInfoItem('Flower Preferences', _getFlowerPreference(sighting)),
                      _buildInfoItem('Social Structure', _getSocialStructure(sighting)),
                    ],
                  ),
                  
                  // New addition: Interaction Guide
                  _buildSection(
                    title: 'Interaction Guide',
                    children: [
                      _buildInfoItem('How to Attract', _getAttractionTips(sighting)),
                      _buildInfoItem('Safe Coexistence', _getSafetyTips(sighting)),
                      _buildInfoItem('Best Observation Practices', 'Maintain a safe distance, avoid disrupting natural behaviors, and use telephoto lenses for observation'),
                    ],
                  ),
                  
                  // New addition: Gardening Suggestions
                  _buildSection(
                    title: 'Gardening Suggestions',
                    children: [
                      _buildInfoItem('Recommended Plants', _getRecommendedPlants(sighting)),
                      _buildInfoItem('Garden Design', _getGardenDesignTips(sighting)),
                      _buildInfoItem('Habitat Creation', 'Provide diverse habitat environments, including exposed soil, dead wood, and water sources to support the complete life cycle'),
                    ],
                  ),
                  
                  // New addition: Seasonal Appearance
                  _buildSection(
                    title: 'Seasonal Appearance',
                    children: [
                      _buildInfoItem('Peak Season', _getPeakSeason(sighting)),
                      _buildInfoItem('Migration Pattern', _getMigrationPattern(sighting)),
                      _buildInfoItem('Winter Activity', _getWinterActivity(sighting)),
                    ],
                  ),
                  
                  // New addition: Conservation Recommendations
                  _buildExpandableSection(
                    title: 'Conservation Recommendations',
                    content: _getConservationAdvice(sighting),
                  ),
                  
                  // New addition: Interesting Facts
                  _buildExpandableSection(
                    title: 'Interesting Facts',
                    content: _getFunFacts(sighting),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Share or export function
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                child: const Text('Share', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonIndicator(Map<String, dynamic> sighting) {
    List<bool> seasonActivity = [false, true, true, true]; // Default: active in spring, summer, fall
    
    if (sighting['plantPreferences'] != null && 
        sighting['plantPreferences'] is Map && 
        (sighting['plantPreferences'] as Map)['season'] != null) {
      String season = (sighting['plantPreferences'] as Map)['season'].toString().toLowerCase();
      
      if (season.contains('spring')) seasonActivity[0] = true;
      if (season.contains('summer')) seasonActivity[1] = true;
      if (season.contains('fall') || season.contains('autumn')) seasonActivity[2] = true;
      if (season.contains('winter')) seasonActivity[3] = true;
      
      // If nothing specified, use default values
      if (!seasonActivity.contains(true)) {
        seasonActivity = [false, true, true, true];
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seasonal Activity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSeasonItem('Spring', seasonActivity[0], Colors.green.shade300),
            _buildSeasonItem('Summer', seasonActivity[1], Colors.orange.shade300),
            _buildSeasonItem('Fall', seasonActivity[2], Colors.brown.shade300),
            _buildSeasonItem('Winter', seasonActivity[3], Colors.blue.shade300),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSeasonItem(String label, bool isActive, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? color.withOpacity(0.8) : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label[0], // First letter of the season
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black87 : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildExpandableSection({required String title, required String content}) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Various helper methods that return information based on pollinator type
  String _getPollinationEfficiency(Map<String, dynamic> sighting) {
    String type = (sighting['pollinatorType'] ?? '').toString().toLowerCase();
    
    if (type.contains('bee')) {
      return 'High - Bees are among the most efficient pollinators, with strong pollen-carrying ability';
    } else if (type.contains('butterfly')) {
      return 'Medium - Butterflies have long proboscises suited for specific flowers, but limited pollen-carrying capacity';
    } else if (type.contains('beetle')) {
      return 'Low to Medium - Beetles have smooth surfaces, but their frequent flower visits compensate for efficiency';
    } else if (type.contains('moth')) {
      return 'Medium - Moths are important night pollinators, suited for white or pale night-blooming flowers';
    } else if (type.contains('fly')) {
      return 'Low to Medium - Flies have lower pollination efficiency due to feeding habits, but they are abundant';
    } else {
      return 'Medium - Each flower visit can carry a moderate amount of pollen, accumulated through multiple visits';
    }
  }

  String _getPollinationRange(Map<String, dynamic> sighting) {
    String type = (sighting['pollinatorType'] ?? '').toString().toLowerCase();
    
    if (type.contains('bee')) {
      return 'Generally active within 2-5 kilometers around their nest';
    } else if (type.contains('butterfly')) {
      return 'Broad, can fly within several kilometers, some species exhibit migratory behavior';
    } else if (type.contains('beetle')) {
      return 'Limited, usually active within a few hundred meters';
    } else if (type.contains('moth')) {
      return 'Medium to wide, can fly several kilometers at night in search of food';
    } else {
      return 'Generally within 300-800 meters, depending on habitat distribution and food availability';
    }
  }

  String _getActivityTime(Map<String, dynamic> sighting) {
    String type = (sighting['pollinatorType'] ?? '').toString().toLowerCase();
    String name = (sighting['pollinatorName'] ?? '').toString().toLowerCase();
    
    if (type.contains('moth') || name.contains('moth')) {
      return 'Mainly active at dusk and night, especially on warm evenings';
    } else if (type.contains('butterfly') || name.contains('butterfly')) {
      return 'Active during the day, especially on sunny days and during warm periods';
    } else if (type.contains('bee') || name.contains('bee')) {
      return 'Active on sunny days from morning to evening, most active when temperatures are above 10°C';
    } else {
      return 'Mainly active during daylight hours, most active when warm and sunny';
    }
  }

  String _getFlowerPreference(Map<String, dynamic> sighting) {
    if (sighting['plantPreferences'] != null && 
        sighting['plantPreferences'] is Map && 
        (sighting['plantPreferences'] as Map)['preferred'] != null) {
      
      List preferred = (sighting['plantPreferences'] as Map)['preferred'] as List;
      return preferred.join(', ');
      
    } else {
      String type = (sighting['pollinatorType'] ?? '').toString().toLowerCase();
      
      if (type.contains('bee')) {
        return 'Prefers bright blue, purple, and yellow flowers, typically tubular or with landing platforms';
      } else if (type.contains('butterfly')) {
        return 'Prefers bright red, orange, pink, and purple flowers, usually with flat landing areas';
      } else if (type.contains('moth')) {
        return 'Prefers white or pale-colored flowers that emit fragrance at night';
      } else {
        return 'Highly adaptable, enjoys various flowers, especially open and shallow ones';
      }
    }
  }

  String _getSocialStructure(Map<String, dynamic> sighting) {
    String type = (sighting['pollinatorType'] ?? '').toString().toLowerCase();
    String name = (sighting['pollinatorName'] ?? '').toString().toLowerCase();
    
    if ((type.contains('bee') || name.contains('bee')) && 
        (name.contains('honey') || name.contains('bumble'))) {
      return 'Social, forms organized colonies with clear division of labor';
    } else if (type.contains('butterfly') || name.contains('butterfly')) {
      return 'Solitary, does not form social groups, but may gather at common feeding or egg-laying sites';
    } else {
      return 'Primarily solitary, occasionally gathering temporarily near abundant food sources';
    }
  }

  String _getAttractionTips(Map<String, dynamic> sighting) {
    String type = (sighting['pollinatorType'] ?? '').toString().toLowerCase();
    
    if (type.contains('bee')) {
      return 'Plant native flowers with successive blooming periods, provide shallow water sources, avoid pesticides';
    } else if (type.contains('butterfly')) {
      return 'Plant nectar sources and host plants for caterpillars, create sunny areas with shade';
    } else if (type.contains('moth')) {
      return 'Plant night-blooming fragrant flowers, reduce nighttime light pollution';
    } else {
      return 'Provide diverse native plants, create multi-layered habitats, maintain organic gardening practices';
    }
  }

  String _getSafetyTips(Map<String, dynamic> sighting) {
    String type = (sighting['pollinatorType'] ?? '').toString().toLowerCase();
    String name = (sighting['pollinatorName'] ?? '').toString().toLowerCase();
    
    if (type.contains('bee') || name.contains('bee')) {
      return 'Keep distance, avoid approaching hives, don\'t make threatening movements, wear light-colored clothing';
    } else if (name.contains('wasp') || name.contains('hornet')) {
      return 'Avoid activities near their nests, don\'t wave arms or make threatening movements, handle food and sweet drinks carefully';
    } else {
      return 'Most pollinators are harmless to humans, maintain appropriate distance when observing, avoid disrupting natural behaviors';
    }
  }

  String _getRecommendedPlants(Map<String, dynamic> sighting) {
    if (sighting['plantPreferences'] != null && 
        sighting['plantPreferences'] is Map && 
        (sighting['plantPreferences'] as Map)['preferred'] != null) {
      
      List preferred = (sighting['plantPreferences'] as Map)['preferred'] as List;
      String plants = preferred.join(', ');
      return '$plants, and other native flowering plants';
      
    } else {
      String type = (sighting['pollinatorType'] ?? '').toString().toLowerCase();
      
      if (type.contains('bee')) {
        return 'Aster, mint, lavender, lungwort, sunflower, marigold, etc.';
      } else if (type.contains('butterfly')) {
        return 'Coneflower, butterfly bush, milkweed, zinnia, pot marigold, etc.';
      } else if (type.contains('moth')) {
        return 'Evening primrose, night-blooming jasmine, moonflower, and other night-blooming flowers';
      } else {
        return 'Mix of various native flowering plants, ensuring blooms across seasons for continuous nectar and pollen sources';
      }
    }
  }

  String _getGardenDesignTips(Map<String, dynamic> sighting) {
    String type = (sighting['pollinatorType'] ?? '').toString().toLowerCase();
    
    if (type.contains('bee')) {
      return 'Plant the same species in clusters to create "color blocks," set up shallow water dishes, leave some bare soil for ground-nesting bees';
    } else if (type.contains('butterfly')) {
      return 'Create sunny and shaded areas, plant host plants for caterpillars, provide flat rocks for sunbathing, set up shallow water dishes';
    } else if (type.contains('moth')) {
      return 'Establish night garden areas, plant fragrant pale flowers, control outdoor lighting';
    } else {
      return 'Plant in layers from ground covers to shrubs and trees, create complete ecosystems, maintain organic management methods';
    }
  }

  String _getPeakSeason(Map<String, dynamic> sighting) {
    if (sighting['plantPreferences'] != null && 
        sighting['plantPreferences'] is Map && 
        (sighting['plantPreferences'] as Map)['season'] != null) {
      
      return (sighting['plantPreferences'] as Map)['season'];
      
    } else {
      return 'Warm months from spring to fall, typically most active from May to September';
    }
  }

  String _getMigrationPattern(Map<String, dynamic> sighting) {
    String name = (sighting['pollinatorName'] ?? '').toString().toLowerCase();
    String type = (sighting['pollinatorType'] ?? '').toString().toLowerCase();
    
    if (name.contains('monarch')) {
      return 'Long-distance migration, traveling thousands of kilometers between North America and Mexico annually';
    } else if (type.contains('butterfly')) {
      return 'Some species exhibit seasonal migration, most active in local areas';
    } else if (type.contains('bee')) {
      return 'Non-migratory, active in fixed areas around their nests';
    } else {
      return 'Mainly active in local areas, no significant migratory behavior';
    }
  }

  String _getWinterActivity(Map<String, dynamic> sighting) {
    String type = (sighting['pollinatorType'] ?? '').toString().toLowerCase();
    
    if (type.contains('bee')) {
      return 'Most bees overwinter in hives, queens and worker bees form winter clusters to stay warm';
    } else if (type.contains('butterfly')) {
      return 'Different species employ different strategies: migration, hibernation, or overwintering as eggs/larvae/pupae';
    } else {
      return 'Most pollinators reduce activity in cold seasons, hibernating in various forms or overwintering in protected areas';
    }
  }

  String _getConservationAdvice(Map<String, dynamic> sighting) {
    String type = (sighting['pollinatorType'] ?? '').toString().toLowerCase();
    String baseAdvice = 'Reduce or avoid pesticides; plant native flowers; provide water sources; preserve natural habitats; support organic farming; participate in citizen science projects to record observations; ';
    
    if (type.contains('bee')) {
      return '$baseAdvice Leave some bare soil for ground-nesting bees; build bee hotels; choose non-hybrid single flowers with richer pollen and nectar; learn local beekeeping regulations and consider supporting local beekeepers.';
    } else if (type.contains('butterfly')) {
      return '$baseAdvice Protect existing butterfly habitats; plant host plants for caterpillars; provide flat, sun-exposed rocks for sunbathing; participate in butterfly monitoring projects; support wetland and grassland conservation; create and certify butterfly gardens.';
    } else {
      return '$baseAdvice Use Integrated Pest Management (IPM) to protect beneficial insects; reduce nighttime light pollution; establish multi-layered plant communities; leave some "messy corners" as habitats; share knowledge with neighbors; advocate for pollinator protection policies.';
    }
  }

  String _getFunFacts(Map<String, dynamic> sighting) {
    String name = (sighting['pollinatorName'] ?? '').toString().toLowerCase();
    String type = (sighting['pollinatorType'] ?? '').toString().toLowerCase();
    
    if (type.contains('bee') || name.contains('bee')) {
      return 'Bees can fly at speeds up to 24 km/h; a worker bee produces about 1/12 teaspoon of honey in its lifetime; bees communicate food locations through "dancing"; bees can recognize human faces; worker bees can flap their wings about 200 times per minute; about one-third of global food crops depend on bee pollination.';
    } else if (type.contains('butterfly') || name.contains('butterfly')) {
      return 'Butterflies taste with their feet; their lifespan ranges from days to months; Monarch butterflies can migrate over 4,800 kilometers; butterfly wings have tiny scales; butterflies can detect ultraviolet light; there are about 17,500 butterfly species worldwide.';
    } else if (type.contains('moth') || name.contains('moth')) {
      return 'There are over 160,000 moth species worldwide, far more than butterflies; many moths have hearing organs that can detect bat ultrasound; frozen moths can enter dormancy and still function after thawing; some moth larvae produce silk, like the silk moth; certain moth larvae can make sounds to deter predators.';
    } else if (type.contains('beetle') || name.contains('beetle')) {
      return 'Beetles are the largest insect group on Earth, accounting for about a quarter of all known insect species; some beetles can lift up to 850 times their body weight; beetles are among the longest-existing insects on Earth, with fossil records dating back 300 million years; some beetles can glow, like fireflies.';
    } else {
      return 'It\'s estimated that there are about 200,000 pollinating animal species worldwide, including about 1,000 vertebrates; pollinators contribute approximately \$235-577 billion to global crop value; some plants have co-evolved unique relationships with specific pollinators, becoming interdependent; certain pollinators can remember specific flower locations and form "flower routes" for efficient foraging.';
    }
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      final DateTime date = (timestamp as Timestamp).toDate();
      // Format date - can use intl package for more options
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showFilterOptions(BuildContext context) {
    // Show a dialog or bottom sheet with filter options
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Sightings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Add filter options here
            // To be implemented based on filtering requirements
          ],
        ),
      ),
    );
  }
}