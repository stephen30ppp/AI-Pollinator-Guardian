import 'package:ai_pollinator_guardian/models/garden_model.dart';
import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/services/firebase_service.dart';
import 'package:ai_pollinator_guardian/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

/// Example service showing how to use the currentUid from FirebaseService
class UserDataService {
  final FirebaseService _firebaseService = FirebaseService();
  final StorageService _storageService = StorageService();
  
  /// Save a garden profile under the user's gardens collection
  Future<bool> saveGardenProfile({
  required Map<String, dynamic> aiResponse,
  required List<String> photoUrls,
}) async {
  try {
    // Get the current user's UID
    final String? uid = _firebaseService.currentUid;

    // Check if the user is authenticated
    if (uid == null) {
      debugPrint('Error: Cannot save garden - no authenticated user');
      return false;
    }
    debugPrint('User UID: $uid');

    // Get the current timestamp
    final Timestamp createdAt = Timestamp.now();
    debugPrint('Timestamp created: $createdAt');

    // Fetch the user's document to get the existing gardens array
    final userDoc = await _firebaseService.firestore.collection('users').doc(uid).get();
    final List<dynamic> gardens = userDoc.data()?['gardens'] ?? [];
    debugPrint('Existing gardens: $gardens');

    // Generate the next garden name
    final String gardenName = 'Garden ${gardens.length + 1}';
    debugPrint('Generated garden name: $gardenName');

    // Prepare the new garden data
    final Map<String, dynamic> newGardenData = {
      'name': gardenName,
      'response': aiResponse,
      'photos': photoUrls,
      'createdAt': createdAt,
    };
    debugPrint('New garden data: $newGardenData');

    // Append the new garden to the gardens array
    gardens.add(newGardenData);
    debugPrint('Updated gardens array: $gardens');

    // Save the updated gardens array back to Firestore
    await _firebaseService.firestore.collection('users').doc(uid).update({
      'gardens': gardens,
    });
    debugPrint('Garden profile successfully saved to Firestore.');

    return true;
  } catch (e) {
    debugPrint('Error saving garden profile: $e');
    return false;
  }
}

  /// Get all garden profiles for the current user
 Future<List<Map<String, dynamic>>> getGardenProfilesByUser() async {
  try {
    // Get the current user's UID
    final String? uid = _firebaseService.currentUid;

    // Check if the user is authenticated
    if (uid == null) {
      debugPrint('Error: Cannot fetch gardens - no authenticated user');
      return [];
    }

    // Fetch the user's document
    final userDoc = await _firebaseService.firestore.collection('users').doc(uid).get();
    final List<dynamic>? gardens = userDoc.data()?['gardens'];

    // If no gardens exist, return an empty list
    if (gardens == null || gardens.isEmpty) {
      return [];
    }

    // Transform the gardens array into a list of maps
    final List<Map<String, dynamic>> gardenProfiles = gardens.map((garden) {
      final gardenData = garden as Map<String, dynamic>;
      return {
        'name': gardenData['name'],
        'photos': gardenData['photos'],
        'response': gardenData['response'],
        'pollinator_score': gardenData['response']['pollinator_score'],
        'analysis': gardenData['response']['analysis'],
        'recommended_plants': gardenData['response']['recommended_plants'],
        'action_plan': gardenData['response']['action_plan'],
        'createdAt': (gardenData['createdAt'] as Timestamp).toDate(),
      };
    }).toList();

    return gardenProfiles;
  } catch (e) {
    debugPrint('Error fetching garden profiles: $e');
    return [];
  }
}
}