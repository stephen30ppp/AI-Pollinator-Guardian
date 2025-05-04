import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for managing user targets in Firestore
class TargetService {
  // ───────────────────────── Singleton ─────────────────────────
  TargetService._internal();
  static final TargetService _instance = TargetService._internal();
  factory TargetService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Target type constants
  static const String SIGHTINGS_TARGET = 'sightings';
  static const String SPECIES_TARGET = 'species';
  static const String GARDENS_TARGET = 'gardens';

  /// Get all user targets
  Future<Map<String, int>> getUserTargets(String userId) async {
    try {
      final docSnapshot = await _db.collection('users').doc(userId).get();
      
      if (!docSnapshot.exists || !docSnapshot.data()!.containsKey('targets')) {
        // Return default targets if none set
        return {
          SIGHTINGS_TARGET: 10,
          SPECIES_TARGET: 5,
          GARDENS_TARGET: 3,
        };
      }
      
      return Map<String, int>.from(docSnapshot.data()!['targets'] ?? {});
    } catch (e) {
      debugPrint('Error fetching user targets: $e');
      // Return default targets on error
      return {
        SIGHTINGS_TARGET: 10,
        SPECIES_TARGET: 5,
        GARDENS_TARGET: 3,
      };
    }
  }

  /// Get a specific target by type
  Future<int> getUserTarget(String userId, String targetType, {int defaultValue = 10}) async {
    try {
      final targets = await getUserTargets(userId);
      return targets[targetType] ?? defaultValue;
    } catch (e) {
      debugPrint('Error fetching specific target: $e');
      return defaultValue;
    }
  }

  /// Update a specific target
  Future<bool> updateUserTarget(String userId, String targetType, int value) async {
    try {
      // Get current targets
      final targets = await getUserTargets(userId);
      
      // Update the specific target
      targets[targetType] = value;
      
      // Update Firestore
      await _db.collection('users').doc(userId).update({
        'targets': targets,
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating user target: $e');
      return false;
    }
  }

  /// Update multiple targets at once
  Future<bool> updateUserTargets(String userId, Map<String, int> targetUpdates) async {
    try {
      // Get current targets
      final targets = await getUserTargets(userId);
      
      // Update with new values
      targets.addAll(targetUpdates);
      
      // Update Firestore
      await _db.collection('users').doc(userId).update({
        'targets': targets,
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating multiple targets: $e');
      return false;
    }
  }
}