import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class IdentifyResult {
  final Map<String, dynamic> identification;
  final Map<String, dynamic> details;
  final Map<String, dynamic> plantPreferences;
  final Map<String, dynamic> conservationImpact;
  final bool notFound;

  IdentifyResult({
    required this.identification,
    required this.details,
    required this.plantPreferences,
    required this.conservationImpact,
    this.notFound = false,
  });

  static IdentifyResult? fromMap(Map<String, dynamic> map) {
    if (map.containsKey('notFound') && map['notFound'] == true) {
      return IdentifyResult(
        identification: {},
        details: {},
        plantPreferences: {},
        conservationImpact: {},
        notFound: true,
      );
    }

    if (!map.containsKey('identification') || 
        !map.containsKey('details') || 
        !map.containsKey('plantPreferences') || 
        !map.containsKey('conservationImpact')) {
      return null;
    }

    return IdentifyResult(
      identification: Map<String, dynamic>.from(map['identification'] ?? {}),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      plantPreferences: Map<String, dynamic>.from(map['plantPreferences'] ?? {}),
      conservationImpact: Map<String, dynamic>.from(map['conservationImpact'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'identification': identification,
      'details': details,
      'plantPreferences': plantPreferences,
      'conservationImpact': conservationImpact,
      'notFound': notFound,
    };
  }

  String get commonName => identification['commonName'] as String? ?? 'Unknown Species';
  String get scientificName => identification['scientificName'] as String? ?? 'Unknown';
  int get confidence => identification['confidence'] as int? ?? 0;
  String get type => identification['type'] as String? ?? 'Unknown';
  String get description => details['description'] as String? ?? 'No description available.';
}