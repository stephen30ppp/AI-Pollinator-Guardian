import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/sighting_model.dart';

class PollinatorService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload an image to Firebase Storage and return the download URL
  Future<String?> uploadImage(String path, Uint8List imageBytes) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putData(imageBytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Save a sighting to Firestore
  Future<void> saveSighting({
    required String species,
    required String location,
    required String imageUrl,
    required DateTime timestamp,
    required String userId,
    required String scientificName,
    required String description,
    required String type,
    required List<String> preferredPlants,
    required String conservationStatus,
    required Map<String, dynamic> additionalInfo,
  }) async {
    try {
      final sighting = PollinatorModel(
        id: DateTime.now().toIso8601String(),
        userId: userId,
        species: species,
        location: GeoPoint(
          double.parse(location.split(',')[0]),
          double.parse(location.split(',')[1]),
        ),
        timestamp: Timestamp.fromDate(timestamp),
        imageUrl: imageUrl,
        scientificName: scientificName,
        description: description,
        type: type,
        preferredPlants: preferredPlants,
        conservationStatus: conservationStatus,
        additionalInfo: additionalInfo,
      );

      await _firestore
          .collection('sightings')
          .doc(sighting.id)
          .set(sighting.toJson());
    } catch (e) {
      print('Error saving sighting: $e');
    }
  }

  /// Fetch sightings for the current user
  Future<List<SightingModel>> getUserSightings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final QuerySnapshot snapshot =
          await _firestore
              .collection('sightings')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .get();

      return snapshot.docs
          .map(
            (doc) => SightingModel.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      print('Error fetching user sightings: $e');
      return [];
    }
  }
}
