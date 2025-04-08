// lib/features/community_map/community_map_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_pollinator_guardian/models/pollinator_model.dart';

class CommunityMapProvider extends ChangeNotifier {
  List<PollinatorModel> _pollinators = [];
  List<PollinatorModel> get pollinators => _pollinators;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? speciesFilter;
  DateTime? startDateFilter;
  DateTime? endDateFilter;
  String? locationFilter; // 用于过滤的位置信息

  Future<void> fetchPollinators() async {
    _isLoading = true;
    notifyListeners();

    // 假数据：注意 additionalInfo 中包含 location 作为 GeoPoint
    _pollinators = [
      PollinatorModel(
        id: '1',
        commonName: 'Bumblebee',
        scientificName: 'Bombus spp.',
        description: 'A common bumblebee species found in gardens.',
        imageUrl: 'https://example.com/bumblebee.jpg',
        type: 'Bee',
        preferredPlants: ['Lavender', 'Sunflower'],
        conservationStatus: 'Least Concern',
        additionalInfo: {
          'location': const GeoPoint(3.1390, 101.6869),
        },
      ),
      PollinatorModel(
        id: '2',
        commonName: 'Monarch Butterfly',
        scientificName: 'Danaus plexippus',
        description: 'A migratory butterfly with distinctive orange and black wings.',
        imageUrl: 'https://example.com/monarch.jpg',
        type: 'Butterfly',
        preferredPlants: ['Milkweed'],
        conservationStatus: 'Vulnerable',
        additionalInfo: {
          // 稍微偏移一点
          'location': const GeoPoint(3.1400, 101.6875),
        },
      ),
    ];

    // 真实数据：这里可以调用 Firestore 查询
    // _pollinators = await repository.queryPollinators(
    //   species: speciesFilter,
    //   startDate: startDateFilter,
    //   endDate: endDateFilter,
    //   location: locationFilter,
    // );

    _isLoading = false;
    notifyListeners();
  }

  void setFilters({
    String? species,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
  }) {
    speciesFilter = species;
    startDateFilter = startDate;
    endDateFilter = endDate;
    locationFilter = location;
    fetchPollinators();
  }
}
