import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/widgets/bottom_navigation_bar.dart';
import 'package:ai_pollinator_guardian/features/community_map/providers/community_map_provider.dart';
import 'package:ai_pollinator_guardian/features/community_map/widgets/sighting_info_card.dart';

class CommunityMapScreen extends StatefulWidget {
  const CommunityMapScreen({super.key});

  @override
  _CommunityMapScreenState createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends State<CommunityMapScreen> {
  GoogleMapController? _mapController;

  bool _showSearch = false;
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();

  // Default center location (can be adjusted based on user's location)
  static const LatLng _defaultCenter = LatLng(3.1390, 101.6869); // Kuala Lumpur

  // Custom map style - Night Lite theme to make markers pop
  final String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e9e9e9"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  }
]
''';

  @override
  void initState() {
    super.initState();
    debugPrint('CommunityMapScreen: initializing');

    // Add logs to check initialization
    debugPrint('CommunityMapScreen: Google Maps API initialization check');
    
    // Load map data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CommunityMapProvider>(
        context,
        listen: false,
      );
      debugPrint('CommunityMapScreen: Start fetching pollinator data');
      provider.fetchPollinators();
      debugPrint('CommunityMapScreen: Start getting current location');
      provider.getCurrentLocation();
      debugPrint('CommunityMapScreen: Data fetch initiated');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    debugPrint('CommunityMapScreen: disposed');
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    debugPrint('CommunityMapScreen: Map controller created');
    _mapController = controller;

    // Apply custom map style
    _mapController?.setMapStyle(_mapStyle);

    // Get current provider
    final provider = Provider.of<CommunityMapProvider>(context, listen: false);

    // If we already have a location, move camera there
    if (provider.currentLocation != null &&
        provider.currentLocation!.latitude != null &&
        provider.currentLocation!.longitude != null) {
      debugPrint(
        'CommunityMapScreen: Moving to current location: ${provider.currentLocation}',
      );
      _moveToLocation(
        LatLng(
          provider.currentLocation!.latitude!,
          provider.currentLocation!.longitude!,
        ),
      );
    }
  }

  void _moveToLocation(LatLng target) {
    debugPrint('CommunityMapScreen: Moving map to $target');
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 14));
  }

  void _onMarkerTapped(String sightingId) {
    debugPrint('CommunityMapScreen: Marker tapped: $sightingId');
    
    // Add haptic feedback for better interaction
    HapticFeedback.selectionClick();

    // Get the details of the tapped sighting
    final provider = Provider.of<CommunityMapProvider>(context, listen: false);
    final sighting = provider.getSightingById(sightingId);

    if (sighting != null) {
      _showSightingDetails(sighting);
    }
  }

  void _showSightingDetails(Map<String, dynamic> sighting) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SightingInfoCard(
        pollinatorName: sighting['commonName'] ?? 'Unknown Pollinator',
        scientificName: sighting['scientificName'] ?? '',
        imageUrl: sighting['imageUrl'] ?? 'https://via.placeholder.com/70',
        spotDate: sighting['timeAgo'] ?? 'Today',
        distance: sighting['distance'] ?? '2.3 km',
        nearbyCount: sighting['nearbyCount'] ?? 5,
        onDirections: () {
          Navigator.pop(context);
          // Get directions implementation would go here
        },
        onMoreInfo: () {
          Navigator.pop(context);
          // Show more info implementation would go here
        },
        onClose: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('CommunityMapScreen: Building screen');
    
    // Calculate safe areas for better positioning
    final topPadding = MediaQuery.of(context).padding.top;
    final kToolbarHeight = AppBar().preferredSize.height;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Community Map',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
              });
              HapticFeedback.lightImpact();
              debugPrint('CommunityMapScreen: Search toggle: $_showSearch');
            },
          ),
        ],
      ),
      body: Consumer<CommunityMapProvider>(
        builder: (context, provider, _) {
          debugPrint(
            'CommunityMapScreen: Building map with ${provider.markers.length} markers',
          );
          
          // Listen for marker taps
          if (provider.selectedMarkerId != null && provider.selectedMarkerId!.isNotEmpty) {
            // Use Future.microtask to ensure it runs after the current build
            Future.microtask(() {
              _onMarkerTapped(provider.selectedMarkerId!);
              // Reset selectedMarkerId to prevent repeated triggers
              provider.onMarkerTapped('');
            });
          }
          
          debugPrint('CommunityMapScreen: Setting up GoogleMap widget');
          return Stack(
            children: [
              // Google Map
              Container(
                color: Colors.grey[200],
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: GoogleMap(
                  onMapCreated: (controller) {
                    debugPrint('CommunityMapScreen: Map creation callback fired');
                    _onMapCreated(controller);
                  },
                  initialCameraPosition: CameraPosition(
                    target:
                        provider.currentLocation != null
                            ? LatLng(
                              provider.currentLocation!.latitude!,
                              provider.currentLocation!.longitude!,
                            )
                            : _defaultCenter,
                    zoom: 14,
                  ),
                  markers: provider.markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: true,
                ),
              ),

              // Search Bar (Floating Search Chip)
              if (_showSearch)
                Positioned(
                  top: topPadding + kToolbarHeight + 16,
                  left: 16,
                  right: 16,
                  child: SearchBar(
                    leading: Icon(Icons.search, color: Colors.grey[600]),
                    trailing: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _showSearch = false;
                            _searchController.clear();
                          });
                        },
                      ),
                    ],
                    hintText: 'Search pollinators...',
                    controller: _searchController,
                    onSubmitted: (value) {
                      provider.searchPollinators(value);
                      setState(() {
                        _showSearch = false;
                      });
                    },
                  ),
                ),

              // Stats Row
              Positioned(
                top: _showSearch ? topPadding + kToolbarHeight + 80 : topPadding + kToolbarHeight - 60,
                left: 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            value: '${provider.todaySightings}',
                            label: 'Sightings Today',
                          ),
                          _buildStatItem(
                            value: '${provider.speciesCount}',
                            label: 'Species',
                          ),
                          _buildStatItem(
                            value: '${provider.searchRadius}km',
                            label: 'Radius',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Map Legend
              Positioned(
                top: _showSearch 
                    ? topPadding + kToolbarHeight + 150 
                    : topPadding + kToolbarHeight + 40,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Pollinator Types',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildLegendItem(
                            color: Colors.amber[600]!,
                            label: 'Bees (${provider.beeSightingsCount})',
                          ),
                          _buildLegendItem(
                            color: Colors.deepPurple[300]!,
                            label: 'Butterflies (${provider.butterflySightingsCount})',
                          ),
                          _buildLegendItem(
                            color: Colors.teal[400]!,
                            label: 'Other (${provider.otherSightingsCount})',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Map Controls
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  children: [
                    _buildMapControlButton(
                      icon: Icons.add,
                      onPressed: () {
                        debugPrint('CommunityMapScreen: Zoom in');
                        HapticFeedback.lightImpact();
                        _mapController?.animateCamera(CameraUpdate.zoomIn());
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMapControlButton(
                      icon: Icons.remove,
                      onPressed: () {
                        debugPrint('CommunityMapScreen: Zoom out');
                        HapticFeedback.lightImpact();
                        _mapController?.animateCamera(CameraUpdate.zoomOut());
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMapControlButton(
                      icon: Icons.my_location,
                      onPressed: () {
                        debugPrint('CommunityMapScreen: My location pressed');
                        HapticFeedback.mediumImpact();
                        if (provider.currentLocation != null) {
                          _moveToLocation(
                            LatLng(
                              provider.currentLocation!.latitude!,
                              provider.currentLocation!.longitude!,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMapControlButton(
                      icon: Icons.refresh,
                      onPressed: () {
                        debugPrint('CommunityMapScreen: Refresh pressed');
                        HapticFeedback.mediumImpact();
                        provider.fetchPollinators();
                      },
                    ),
                  ],
                ),
              ),

              // Filter Button (Bottom Left)
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Semantics(
                    label: _showFilters ? 'Close filters' : 'Show filters',
                    child: IconButton(
                      icon: Icon(
                        _showFilters ? Icons.close : Icons.filter_list,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                        HapticFeedback.mediumImpact();
                        debugPrint(
                          'CommunityMapScreen: Filter toggle: $_showFilters',
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Filter Sheet (Conditionally shown)
              if (_showFilters)
                Positioned(
                  top: _showSearch 
                      ? topPadding + kToolbarHeight + 150 
                      : topPadding + kToolbarHeight + 86,
                  left: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: _buildFilterCard(provider),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: PollinatorBottomNavBar(
        selectedIndex: 2, // Map is selected
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/identify');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/garden');
          }
        },
      ),
    );
  }

  Widget _buildStatItem({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24, // Increased from 20 for better typography rhythm
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        Text(
          label, 
          style: TextStyle(
            fontSize: 12, 
            color: Colors.grey[600]
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
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
          Expanded(
            child: Text(
              label, 
              style: TextStyle(
                fontSize: 12, 
                color: Colors.grey[800]
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 48, // Increased from 40 for better tappability
      height: 48, // Increased from 40 for better tappability
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: Colors.black87,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildFilterCard(CommunityMapProvider provider) {
    return Card(
      elevation: 0, // Reduced since we have backdrop filter
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white.withOpacity(0.85),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Sightings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFilters = false;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Icon(Icons.close, size: 20, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Pollinator Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip(
                  label: 'All',
                  isSelected: provider.pollinatorTypeFilter == null,
                  onTap: () {
                    provider.setPollinatorTypeFilter(null);
                    HapticFeedback.selectionClick();
                  },
                ),
                _buildFilterChip(
                  label: 'Bees',
                  isSelected: provider.pollinatorTypeFilter == 'bee',
                  onTap: () {
                    provider.setPollinatorTypeFilter('bee');
                    HapticFeedback.selectionClick();
                  },
                ),
                _buildFilterChip(
                  label: 'Butterflies',
                  isSelected: provider.pollinatorTypeFilter == 'butterfly',
                  onTap: () {
                    provider.setPollinatorTypeFilter('butterfly');
                    HapticFeedback.selectionClick();
                  },
                ),
                _buildFilterChip(
                  label: 'Beetles',
                  isSelected: provider.pollinatorTypeFilter == 'beetle',
                  onTap: () {
                    provider.setPollinatorTypeFilter('beetle');
                    HapticFeedback.selectionClick();
                  },
                ),
                _buildFilterChip(
                  label: 'Other',
                  isSelected: provider.pollinatorTypeFilter == 'other',
                  onTap: () {
                    provider.setPollinatorTypeFilter('other');
                    HapticFeedback.selectionClick();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Date Range',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Select start date',
                    child: InkWell(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: provider.startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          provider.setDateRange(
                            startDate: date,
                            endDate: provider.endDate,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          provider.startDate != null
                              ? '${provider.startDate!.day}/${provider.startDate!.month}/${provider.startDate!.year}'
                              : 'Start Date',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                provider.startDate != null
                                    ? Colors.black
                                    : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('to'),
                const SizedBox(width: 16),
                Expanded(
                  child: Semantics(
                    label: 'Select end date',
                    child: InkWell(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: provider.endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          provider.setDateRange(
                            startDate: provider.startDate,
                            endDate: date,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          provider.endDate != null
                              ? '${provider.endDate!.day}/${provider.endDate!.month}/${provider.endDate!.year}'
                              : 'End Date',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                provider.endDate != null
                                    ? Colors.black
                                    : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Search Radius',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${provider.searchRadius} km',
                  style: const TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w500
                  ),
                ),
              ],
            ),
            Slider(
              value: provider.searchRadius.toDouble(),
              min: 1,
              max: 50,
              divisions: 49,
              activeColor: AppColors.primaryColor,
              label: '${provider.searchRadius} km',
              onChanged: (value) {
                provider.setSearchRadius(value.round());
              },
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'Apply filters',
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _showFilters = false;
                  });
                  HapticFeedback.mediumImpact();
                  provider.applyFilters();
                },
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'Reset all filters',
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  provider.resetFilters();
                },
                child: const Text(
                  'Reset All',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Determine color based on label for semantic coloring
    Color? chipColor;
    if (label == 'Bees') {
      chipColor = Colors.amber[600];
    } else if (label == 'Butterflies') {
      chipColor = Colors.deepPurple[300];
    } else if (label == 'Beetles') {
      chipColor = Colors.brown[400];
    } else if (label == 'Other') {
      chipColor = Colors.teal[400];
    } else {
      chipColor = isSelected ? AppColors.primaryColor : Colors.grey[200];
    }
    
    return Semantics(
      button: true,
      label: 'Filter by $label',
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8, right: 8),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ] : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}