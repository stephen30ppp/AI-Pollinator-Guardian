import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SightingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get a stream of sightings for a specific user
  Stream<QuerySnapshot> getUserSightings(String userId) {
    return _firestore
      .collection('users')
      .doc(userId)
      .collection('sightings')
      .orderBy('timestamp', descending: true)
      .snapshots();
  }

  /// Get a single sighting by ID
  Future<DocumentSnapshot?> getSightingById(String userId, String sightingId) async {
    try {
      return await _firestore
        .collection('users')
        .doc(userId)
        .collection('sightings')
        .doc(sightingId)
        .get();
    } catch (e) {
      return null;
    }
  }

  /// Add a new sighting
  Future<bool> addSighting(String userId, Map<String, dynamic> sightingData) async {
    try {
      await _firestore
        .collection('users')
        .doc(userId)
        .collection('sightings')
        .add({
          ...sightingData,
          'timestamp': FieldValue.serverTimestamp(),
        });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a sighting
  Future<bool> deleteSighting(String userId, String sightingId) async {
    try {
      await _firestore
        .collection('users')
        .doc(userId)
        .collection('sightings')
        .doc(sightingId)
        .delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get the count of sightings for a user
  Future<int> getSightingsCount(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sightings')
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting sightings count: $e');
      return 0;
    }
  }

  /// Get the count of unique species identified by a user
  Future<int> getUniqueSpeciesCount(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sightings')
          .get();
      
      // Use a Set to count unique species by scientific name
      final Set<String> uniqueSpecies = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('pollinatorId') && data['pollinatorId'] != null) {
          uniqueSpecies.add(data['pollinatorId'] as String);
        }
      }
      
      return uniqueSpecies.length;
    } catch (e) {
      debugPrint('Error getting unique species count: $e');
      return 0;
    }
  }
}