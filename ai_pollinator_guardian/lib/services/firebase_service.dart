import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../models/sighting_model.dart';
import '../models/garden_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth methods
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  Future<User?> createUserWithEmailAndPassword(String email, String password, String name) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user profile
      if (result.user != null) {
        await _createUserProfile(result.user!.uid, name, email);
        return result.user;
      }
      return null;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  // Firestore methods
  Future<void> _createUserProfile(String uid, String name, String email) async {
    await _firestore.collection('users').doc(uid).set({
      'id': uid,
      'name': name,
      'email': email,
      'photoUrl': null,
      'sightings': [],
      'gardens': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // User profile methods
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Sightings methods
  Future<void> saveSighting(SightingModel sighting) async {
    try {
      await _firestore.collection('sightings').doc(sighting.id).set(sighting.toJson());
      
      // Update user's sightings list
      await _firestore.collection('users').doc(sighting.userId).update({
        'sightings': FieldValue.arrayUnion([sighting.id]),
      });
    } catch (e) {
      print('Error saving sighting: $e');
    }
  }

  Future<List<SightingModel>> getUserSightings(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('sightings')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => SightingModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting user sightings: $e');
      return [];
    }
  }

  Future<List<SightingModel>> getNearbySightings(GeoPoint location, double radiusKm) async {
    // For simplicity in this hackathon, we're just getting recent sightings
    // In a real app, you'd use geohashing or a more advanced geo query
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('sightings')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs
          .map((doc) => SightingModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting nearby sightings: $e');
      return [];
    }
  }

  // Garden methods
  Future<void> saveGarden(GardenModel garden) async {
    try {
      await _firestore.collection('gardens').doc(garden.id).set(garden.toJson());
      
      // Update user's gardens list
      await _firestore.collection('users').doc(garden.userId).update({
        'gardens': FieldValue.arrayUnion([garden.id]),
      });
    } catch (e) {
      print('Error saving garden: $e');
    }
  }

  Future<List<GardenModel>> getUserGardens(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('gardens')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => GardenModel.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting user gardens: $e');
      return [];
    }
  }

  // Storage methods
  Future<String> uploadImage(String path, List<int> imageBytes) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(Uint8List.fromList(imageBytes));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }
}