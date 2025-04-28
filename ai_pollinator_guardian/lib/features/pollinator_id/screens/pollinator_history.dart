import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PollinatorHistory extends StatelessWidget {
  final String userId;

  const PollinatorHistory({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identification History'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('sightings')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final sightings = snapshot.data?.docs ?? [];
          if (sightings.isEmpty) {
            return const Center(child: Text('No sightings found'));
          }

          // Filter out repeated pollinators
          final uniqueSightings = <String, Map<String, dynamic>>{};
          for (var doc in sightings) {
            final sighting = doc.data() as Map<String, dynamic>;
            final pollinatorId = sighting['pollinatorId'];
            if (!uniqueSightings.containsKey(pollinatorId)) {
              uniqueSightings[pollinatorId] = sighting;
            }
          }

          final filteredSightings = uniqueSightings.values.toList();

          return ListView.builder(
            itemCount: filteredSightings.length,
            itemBuilder: (context, index) {
              final sighting = filteredSightings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display the image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          sighting['imageUrl'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 40),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Display the details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sighting['pollinatorName'] ??
                                  'Unknown Pollinator',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scientific Name: ${sighting['pollinatorId'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Confidence: ${sighting['confidence']?.toStringAsFixed(2) ?? 'N/A'}%',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${sighting['timestamp'].toDate()}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
