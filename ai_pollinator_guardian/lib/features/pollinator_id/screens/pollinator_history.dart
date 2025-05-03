import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/services/sighting_service.dart';
import 'package:ai_pollinator_guardian/features/pollinator_id/widgets/sighting_card.dart';
import 'package:ai_pollinator_guardian/features/pollinator_id/widgets/empty_sightings_view.dart';

class PollinatorHistory extends StatelessWidget {
  final String userId;
  final SightingService _sightingService = SightingService();

  PollinatorHistory({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Identification History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(context),
            tooltip: 'Filter sightings',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _sightingService.getUserSightings(userId),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            );
          }
          
          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
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
          }

          // Empty state
          final sightings = snapshot.data?.docs ?? [];
          if (sightings.isEmpty) {
            return EmptySightingsView(
              onAddSighting: () => Navigator.of(context).pushNamed('/identify'),
            );
          }

          // Content state - List of sightings
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: sightings.length,
            itemBuilder: (context, index) {
              final sighting = sightings[index].data() as Map<String, dynamic>;
              final sightingId = sightings[index].id;
              
              return SightingCard(
                sighting: sighting,
                onTap: () => _showSightingDetails(context, sightingId, sighting),
              );
            },
          );
        },
      ),
      // Optional: Add a floating action button to identify new pollinators
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
        onPressed: () => Navigator.of(context).pushNamed('/identify'),
      ),
    );
  }

  void _showSightingDetails(BuildContext context, String sightingId, Map<String, dynamic> sighting) {
    // Navigate to a detail page or show a dialog with more information
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildDetailSheet(context, sightingId, sighting),
    );
  }

  Widget _buildDetailSheet(BuildContext context, String sightingId, Map<String, dynamic> sighting) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            sighting['pollinatorName'] ?? 'Unknown Pollinator',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display more detailed information here
                  // To be expanded based on available sighting data
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Share or export functionality
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                child: const Text('Share', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    // Show a dialog or bottom sheet with filter options
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Sightings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Add filter options here
            // To be implemented based on filtering requirements
          ],
        ),
      ),
    );
  }
}