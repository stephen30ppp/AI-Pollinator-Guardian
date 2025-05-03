import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/widgets/garden_card.dart';

class GardenHistoryScreen extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  GardenHistoryScreen({super.key});

  Future<List<Map<String, dynamic>>> _getGardenProfilesByUser() async {
    if (_firebaseService.currentUid == null) {
      return [];
    }
    
    try {
      // Get the user profile to get garden IDs
      final userProfile = await _firebaseService.getUserProfile(_firebaseService.currentUid!);
      
      if (userProfile == null || userProfile.gardens.isEmpty) {
        return [];
      }
      
      // Prepare a list to hold garden data
      final List<Map<String, dynamic>> gardens = [];
      
      // For each garden ID, fetch the garden document
      for (String gardenId in userProfile.gardens) {
        try {
          final gardenDoc = await FirebaseFirestore.instance
              .collection('gardens')
              .doc(gardenId)
              .get();
              
          if (gardenDoc.exists) {
            gardens.add({
              'id': gardenDoc.id,
              ...gardenDoc.data()!,
            });
          }
        } catch (e) {
          debugPrint('Error fetching garden $gardenId: $e');
        }
      }
      
      // Sort by creation date (newest first)
      gardens.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        
        return bDate.compareTo(aDate);
      });
      
      return gardens;
    } catch (e) {
      debugPrint('Error getting garden profiles: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Garden History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getGardenProfilesByUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading history: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Force refresh
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco, size: 64, color: Colors.green[200]),
                  const SizedBox(height: 16),
                  const Text(
                    'No garden scans yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan your garden to see history here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final gardens = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: gardens.length,
            itemBuilder: (context, index) {
              final garden = gardens[index];
              return GardenCard(garden: garden);
            },
          );
        },
      ),
    );
  }
}