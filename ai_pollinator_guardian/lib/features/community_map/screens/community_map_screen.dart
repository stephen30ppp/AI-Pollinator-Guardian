import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/widgets/bottom_navigation_bar.dart';
import 'package:ai_pollinator_guardian/features/community_map/providers/community_map_provider.dart';

class CommunityMapScreen extends StatefulWidget {
  const CommunityMapScreen({Key? key}) : super(key: key);

  @override
  _CommunityMapScreenState createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends State<CommunityMapScreen> {
  GoogleMapController? _mapController;

  // Default center location (can be adjusted based on user's location)
  static const LatLng _defaultCenter = LatLng(3.1390, 101.6869); // Kuala Lumpur

  // Map style - You can customize this if needed
  String _mapStyle = '';

  // Filter dialog visibility
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    debugPrint('CommunityMapScreen: initializing');

    // Load map data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CommunityMapProvider>(
        context,
        listen: false,
      );
      provider.fetchPollinators();
      provider.getCurrentLocation();
      debugPrint('CommunityMapScreen: Data fetch initiated');
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    debugPrint('CommunityMapScreen: disposed');
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    debugPrint('CommunityMapScreen: Map controller created');
    _mapController = controller;

    // Apply custom map style if needed
    if (_mapStyle.isNotEmpty) {
      _mapController?.setMapStyle(_mapStyle);
    }

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
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sighting details header
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(
                            sighting['imageUrl'] ??
                                'https://via.placeholder.com/70',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sighting['commonName'] ?? 'Unknown Pollinator',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            sighting['scientificName'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Details grid
                Row(
                  children: [
                    _buildDetailItem(
                      label: 'Spotted',
                      value: sighting['timeAgo'] ?? 'Today',
                    ),
                    const VerticalDivider(
                      thickness: 1,
                      width: 1,
                      color: Colors.grey,
                    ),
                    _buildDetailItem(
                      label: 'Distance',
                      value: sighting['distance'] ?? '2.3 km',
                    ),
                    const VerticalDivider(
                      thickness: 1,
                      width: 1,
                      color: Colors.grey,
                    ),
                    _buildDetailItem(
                      label: 'Nearby',
                      value: '${sighting['nearbyCount'] ?? 5}',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          // Get directions implementation would go here
                        },
                        child: const Text('Directions'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          // Show more info implementation would go here
                        },
                        child: const Text('More Info'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailItem({required String label, required String value}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              debugPrint('CommunityMapScreen: Search button pressed');
              // Implement search functionality
            },
          ),
        ],
      ),
      body: Consumer<CommunityMapProvider>(
        builder: (context, provider, _) {
          debugPrint(
            'CommunityMapScreen: Building map with ${provider.markers.length} markers',
          );
          return Stack(
            children: [
              // Google Map
              GoogleMap(
                onMapCreated: _onMapCreated,
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
                compassEnabled: false,
              ),

              // Stats Row
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
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

              // Map Legend
              Positioned(
                top: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Pollinator Types',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem(
                          color: Colors.amber,
                          label: 'Bees (${provider.beeSightingsCount})',
                        ),
                        _buildLegendItem(
                          color: Colors.deepOrange,
                          label:
                              'Butterflies (${provider.butterflySightingsCount})',
                        ),
                        _buildLegendItem(
                          color: Colors.purple,
                          label: 'Other (${provider.otherSightingsCount})',
                        ),
                      ],
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
                        _mapController?.animateCamera(CameraUpdate.zoomIn());
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMapControlButton(
                      icon: Icons.remove,
                      onPressed: () {
                        debugPrint('CommunityMapScreen: Zoom out');
                        _mapController?.animateCamera(CameraUpdate.zoomOut());
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMapControlButton(
                      icon: Icons.my_location,
                      onPressed: () {
                        debugPrint('CommunityMapScreen: My location pressed');
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
                        provider.fetchPollinators();
                      },
                    ),
                  ],
                ),
              ),

              // Filter Sheet (Conditionally shown)
              if (_showFilters)
                Positioned(
                  top: 80,
                  left: 16,
                  right: 16,
                  child: _buildFilterCard(provider),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showFilters = !_showFilters;
          });
          debugPrint('CommunityMapScreen: Filter toggle: $_showFilters');
        },
        backgroundColor: AppColors.primaryColor,
        child: Icon(
          _showFilters ? Icons.close : Icons.filter_list,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: PollinatorBottomNavBar(
        selectedIndex: 2, // Map is selected
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/identify');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/garden');
          } else if (index == 4) {
            Navigator.pushNamed(context, '/chat');
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
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
        icon: Icon(icon, size: 18),
        color: Colors.black87,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildFilterCard(CommunityMapProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Sightings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFilters = false;
                    });
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
                  },
                ),
                _buildFilterChip(
                  label: 'Bees',
                  isSelected: provider.pollinatorTypeFilter == 'bee',
                  onTap: () {
                    provider.setPollinatorTypeFilter('bee');
                  },
                ),
                _buildFilterChip(
                  label: 'Butterflies',
                  isSelected: provider.pollinatorTypeFilter == 'butterfly',
                  onTap: () {
                    provider.setPollinatorTypeFilter('butterfly');
                  },
                ),
                _buildFilterChip(
                  label: 'Beetles',
                  isSelected: provider.pollinatorTypeFilter == 'beetle',
                  onTap: () {
                    provider.setPollinatorTypeFilter('beetle');
                  },
                ),
                _buildFilterChip(
                  label: 'Other',
                  isSelected: provider.pollinatorTypeFilter == 'other',
                  onTap: () {
                    provider.setPollinatorTypeFilter('other');
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
                  child: InkWell(
                    onTap: () async {
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
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
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
                const SizedBox(width: 16),
                const Text('to'),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
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
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
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
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Search Radius',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
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
            const SizedBox(height: 8),
            Text(
              '${provider.searchRadius} km',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                setState(() {
                  _showFilters = false;
                });
                provider.applyFilters();
              },
              child: const Text('Apply Filters'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                provider.resetFilters();
              },
              child: const Text('Reset All'),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
