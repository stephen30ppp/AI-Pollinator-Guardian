import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PollinatorHistory extends StatelessWidget {
  final String userId;

  const PollinatorHistory({super.key, required this.userId});

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

          return ListView.builder(
            itemCount: sightings.length,
            itemBuilder: (context, index) {
              final sighting = sightings[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display the image
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child:
                          sighting['imageUrl'] != null
                              ? Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(sighting['imageUrl']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                              : Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.photo,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pollinator Name
                          Text(
                            sighting['pollinatorName'] ?? 'Unknown Pollinator',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Scientific Name
                          Text(
                            'Scientific Name: ${sighting['pollinatorId'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          // Confidence
                          Text(
                            'Confidence: ${sighting['confidence']?.toStringAsFixed(2) ?? 'N/A'}%',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          // Timestamp
                          Text(
                            'Date: ${sighting['timestamp'] != null ? (sighting['timestamp'] as Timestamp).toDate() : 'N/A'}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
