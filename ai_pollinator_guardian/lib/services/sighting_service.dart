import 'package:cloud_firestore/cloud_firestore.dart';

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
}