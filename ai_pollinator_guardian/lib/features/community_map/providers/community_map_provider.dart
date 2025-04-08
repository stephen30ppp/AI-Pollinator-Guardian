import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';

class CommunityMapProvider with ChangeNotifier {
  // Location service
  final Location _location = Location();
  LocationData? currentLocation;
  
  // Sightings data
  List<Map<String, dynamic>> _sightings = [];
  Set<Marker> _markers = {};
  
  // Statistics
  int _todaySightings = 0;
  int _speciesCount = 0;
  int _beeSightingsCount = 0;
  int _butterflySightingsCount = 0;
  int _otherSightingsCount = 0;
  
  // Filters
  String? _pollinatorTypeFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  int _searchRadius = 5;
  
  // Loading state
  bool _isLoading = false;

  // Getters
  Set<Marker> get markers => _markers;
  bool get isLoading => _isLoading;
  int get todaySightings => _todaySightings;
  int get speciesCount => _speciesCount;
  int get searchRadius => _searchRadius;
  int get beeSightingsCount => _beeSightingsCount;
  int get butterflySightingsCount => _butterflySightingsCount;
  int get otherSightingsCount => _otherSightingsCount;
  String? get pollinatorTypeFilter => _pollinatorTypeFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  
  // Get a sighting by ID
  Map<String, dynamic>? getSightingById(String id) {
    try {
      return _sightings.firstWhere((s) => s['id'] == id);
    } catch (e) {
      debugPrint('CommunityMapProvider: Could not find sighting with ID: $id');
      return null;
    }
  }
  
  // Fetch the user's current location
  Future<void> getCurrentLocation() async {
    debugPrint('CommunityMapProvider: Getting current location');
    
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    
    // Check if location services are enabled
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        debugPrint('CommunityMapProvider: Location services disabled');
        return;
      }
    }
    
    // Check if permission is granted
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        debugPrint('CommunityMapProvider: Location permission denied');
        return;
      }
    }
    
    // Get location
    try {
      _location.changeSettings(accuracy: LocationAccuracy.high);
      final locationData = await _location.getLocation();
      currentLocation = locationData;
      debugPrint('CommunityMapProvider: Location obtained: ${locationData.latitude}, ${locationData.longitude}');
      notifyListeners();
    } catch (e) {
      debugPrint('CommunityMapProvider: Error getting location: $e');
    }
  }
  
  // Fetch pollinators data
  Future<void> fetchPollinators() async {
    debugPrint('CommunityMapProvider: Fetching pollinators data');
    _isLoading = true;
    notifyListeners();
    
    try {
      // In a real app, this would fetch from Firebase or an API
      // For now, we'll use mock data
      await Future.delayed(const Duration(seconds: 1));
      
      // Generate mock data
      _generateMockData();
      _updateStatistics();
      _createMarkers();
      
      _isLoading = false;
      notifyListeners();
      
      debugPrint('CommunityMapProvider: Data fetched successfully');
    } catch (e) {
      _isLoading = false;
      debugPrint('CommunityMapProvider: Error fetching data: $e');
      notifyListeners();
    }
  }
  
  // Create markers from sightings
  void _createMarkers() {
    debugPrint('CommunityMapProvider: Creating markers from sightings');
    
    // Filter sightings based on current filters
    final filteredSightings = _getFilteredSightings();
    
    // Create markers
    _markers = filteredSightings.map((sighting) {
      final id = sighting['id'] as String;
      final lat = sighting['latitude'] as double;
      final lng = sighting['longitude'] as double;
      final type = sighting['type'] as String;
      
      // Choose marker color based on type
      BitmapDescriptor markerIcon;
      switch (type.toLowerCase()) {
        case 'bee':
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
          break;
        case 'butterfly':
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
          break;
        default:
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      }
      
      return Marker(
        markerId: MarkerId(id),
        position: LatLng(lat, lng),
        icon: markerIcon,
        onTap: () {
          debugPrint('CommunityMapProvider: Marker tapped: $id');
          // This will be handled by the UI
        },
      );
    }).toSet();
    
    debugPrint('CommunityMapProvider: Created ${_markers.length} markers');
  }
  
  // Update statistics based on current data
  void _updateStatistics() {
    // Count today's sightings
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    _todaySightings = _sightings.where((s) {
      final sightingDate = s['date'] as DateTime;
      return sightingDate.isAfter(today) || 
             sightingDate.isAtSameMomentAs(today);
    }).length;
    
    // Count unique species
    final speciesSet = _sightings.map((s) => s['scientificName'] as String).toSet();
    _speciesCount = speciesSet.length;
    
    // Count by type
    _beeSightingsCount = _sightings.where((s) => 
      (s['type'] as String).toLowerCase() == 'bee'
    ).length;
    
    _butterflySightingsCount = _sightings.where((s) => 
      (s['type'] as String).toLowerCase() == 'butterfly'
    ).length;
    
    _otherSightingsCount = _sightings.where((s) => 
      (s['type'] as String).toLowerCase() != 'bee' && 
      (s['type'] as String).toLowerCase() != 'butterfly'
    ).length;
    
    debugPrint('CommunityMapProvider: Statistics updated - '
        'Today: $_todaySightings, '
        'Species: $_speciesCount, '
        'Bees: $_beeSightingsCount, '
        'Butterflies: $_butterflySightingsCount, '
        'Others: $_otherSightingsCount');
  }
  
  // Apply filters to the data
  void applyFilters() {
    debugPrint('CommunityMapProvider: Applying filters - '
        'Type: $_pollinatorTypeFilter, '
        'Start: $_startDate, '
        'End: $_endDate, '
        'Radius: $_searchRadius km');
    
    _createMarkers();
    notifyListeners();
  }
  
  // Reset all filters
  void resetFilters() {
    debugPrint('CommunityMapProvider: Resetting all filters');
    
    _pollinatorTypeFilter = null;
    _startDate = null;
    _endDate = null;
    _searchRadius = 5;
    
    _createMarkers();
    notifyListeners();
  }
  
  // Set pollinator type filter
  void setPollinatorTypeFilter(String? type) {
    debugPrint('CommunityMapProvider: Setting pollinator type filter: $type');
    _pollinatorTypeFilter = type;
    notifyListeners();
  }
  
  // Set date range filter
  void setDateRange({DateTime? startDate, DateTime? endDate}) {
    debugPrint('CommunityMapProvider: Setting date range - Start: $startDate, End: $endDate');
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
  }
  
  // Set search radius
  void setSearchRadius(int radius) {
    debugPrint('CommunityMapProvider: Setting search radius: $radius km');
    _searchRadius = radius;
    notifyListeners();
  }
  
  // Get filtered sightings based on current filters
  List<Map<String, dynamic>> _getFilteredSightings() {
    return _sightings.where((sighting) {
      // Filter by type
      if (_pollinatorTypeFilter != null && 
          (sighting['type'] as String).toLowerCase() != _pollinatorTypeFilter!.toLowerCase()) {
        return false;
      }
      
      // Filter by date range
      if (_startDate != null) {
        final sightingDate = sighting['date'] as DateTime;
        if (sightingDate.isBefore(_startDate!)) {
          return false;
        }
      }
      
      if (_endDate != null) {
        final sightingDate = sighting['date'] as DateTime;
        // Include the end date by creating a date for the end of that day
        final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        if (sightingDate.isAfter(endOfDay)) {
          return false;
        }
      }
      
      // Filter by radius
      if (currentLocation != null) {
        // Calculate distance from current location
        // In a real app, you'd implement proper distance calculation
        // For this demo, we'll assume all sightings are within range
      }
      
      return true;
    }).toList();
  }
  
  // Generate mock data for demonstration
  void _generateMockData() {
    debugPrint('CommunityMapProvider: Generating mock data');
    
    // Get a center point for the mock data
    double centerLat = currentLocation?.latitude ?? 3.1390;
    double centerLng = currentLocation?.longitude ?? 101.6869;
    
    _sightings = [
      {
        'id': '1',
        'commonName': 'Buff-tailed Bumblebee',
        'scientificName': 'Bombus terrestris',
        'type': 'bee',
        'description': 'Large and fuzzy with a white tail and yellow bands',
        'latitude': centerLat + 0.002,
        'longitude': centerLng + 0.003,
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/d/d4/Bombus_terrestris_%28flying%29.jpg',
        'date': DateTime.now().subtract(const Duration(hours: 3)),
        'timeAgo': '3 hours ago',
        'distance': '0.4 km',
        'nearbyCount': 3,
      },
      {
        'id': '2',
        'commonName': 'Monarch Butterfly',
        'scientificName': 'Danaus plexippus',
        'type': 'butterfly',
        'description': 'Bright orange with black veins and white spots',
        'latitude': centerLat - 0.001,
        'longitude': centerLng + 0.002,
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/e/ea/Monarch_in_flight_over_zinnia_flower.jpg',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'timeAgo': 'Yesterday',
        'distance': '0.2 km',
        'nearbyCount': 2,
      },
      {
        'id': '3',
        'commonName': 'European Honey Bee',
        'scientificName': 'Apis mellifera',
        'type': 'bee',
        'description': 'Yellow and brown stripes with fuzzy body',
        'latitude': centerLat + 0.003,
        'longitude': centerLng - 0.001,
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/4/4d/Apis_mellifera_Western_honey_bee.jpg',
        'date': DateTime.now().subtract(const Duration(hours: 6)),
        'timeAgo': '6 hours ago',
        'distance': '0.6 km',
        'nearbyCount': 8,
      },
      {
        'id': '4',
        'commonName': 'Painted Lady Butterfly',
        'scientificName': 'Vanessa cardui',
        'type': 'butterfly',
        'description': 'Orange-brown with black and white spots',
        'latitude': centerLat - 0.002,
        'longitude': centerLng - 0.003,
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/c/c5/Vanessa_cardui_-_Painted_Lady_on_Buddleja.jpg',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'timeAgo': '2 days ago',
        'distance': '0.7 km',
        'nearbyCount': 1,
      },
      {
        'id': '5',
        'commonName': 'Hoverfly',
        'scientificName': 'Syrphidae family',
        'type': 'other',
        'description': 'Looks like a bee or wasp but has only one pair of wings',
        'latitude': centerLat,
        'longitude': centerLng + 0.004,
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/9/9c/Syrphidae_poster.jpg',
        'date': DateTime.now().subtract(const Duration(hours: 24)),
        'timeAgo': '1 day ago',
        'distance': '0.5 km',
        'nearbyCount': 2,
      },
      {
        'id': '6',
        'commonName': 'Carpenter Bee',
        'scientificName': 'Xylocopa species',
        'type': 'bee',
        'description': 'Large, dark-colored bee with shiny abdomen',
        'latitude': centerLat - 0.003,
        'longitude': centerLng + 0.001,
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/3/32/Carpenter_bee%2C_Ithaca%2C_NY.jpg',
        'date': DateTime.now().subtract(const Duration(hours: 12)),
        'timeAgo': '12 hours ago',
        'distance': '0.8 km',
        'nearbyCount': 1,
      },
      {
        'id': '7',
        'commonName': 'Swallowtail Butterfly',
        'scientificName': 'Papilio machaon',
        'type': 'butterfly',
        'description': 'Yellow with black stripes and blue spots',
        'latitude': centerLat + 0.0015,
        'longitude': centerLng - 0.0025,
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/6/6c/Schmetterling_Schwalbenschwanz_2011.jpg',
        'date': DateTime.now(),
        'timeAgo': 'Today',
        'distance': '0.3 km',
        'nearbyCount': 3,
      },
      {
        'id': '8',
        'commonName': 'Bumblebee',
        'scientificName': 'Bombus pascuorum',
        'type': 'bee',
        'description': 'Ginger-colored all over with no distinct bands',
        'latitude': centerLat + 0.002,
        'longitude': centerLng - 0.002,
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/e/e2/Bombus_pascuorum_-_Flickr_-_gailhampshire.jpg',
        'date': DateTime.now().subtract(const Duration(hours: 5)),
        'timeAgo': '5 hours ago',
        'distance': '0.5 km',
        'nearbyCount': 2,
      },
    ];
    
    debugPrint('CommunityMapProvider: Generated ${_sightings.length} mock sightings');
  }
}