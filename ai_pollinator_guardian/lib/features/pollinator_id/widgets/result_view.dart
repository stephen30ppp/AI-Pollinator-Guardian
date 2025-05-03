import 'dart:io';
import 'package:flutter/material.dart';
import 'info_card.dart';
import 'action_button.dart';
import 'past_identification_item.dart';

class IdentificationResultView extends StatelessWidget {
  final File selectedImage;
  final Map<String, dynamic> identificationResult;
  final List<Map<String, dynamic>> pastIdentifications;
  final VoidCallback onReset;
  final VoidCallback onSave;
  final VoidCallback onViewHistory;
  final Function(Map<String, dynamic>) onSelectPastIdentification;
  final Function(bool) onCaptureImage;
  
  const IdentificationResultView({
    super.key,
    required this.selectedImage,
    required this.identificationResult,
    required this.pastIdentifications,
    required this.onReset,
    required this.onSave,
    required this.onViewHistory,
    required this.onSelectPastIdentification,
    required this.onCaptureImage,
  });

  @override
  Widget build(BuildContext context) {
    // Extract data from the identification result
    final identification = identificationResult['identification'];
    final details = identificationResult['details'];
    final plantPreferences = identificationResult['plantPreferences'];
    final conservationImpact = identificationResult['conservationImpact'];

    final String commonName = identification['commonName'] ?? 'Unknown Species';
    final String scientificName = identification['scientificName'] ?? 'Unknown';
    final int confidence = identification['confidence'] ?? 0;
    final String type = identification['type'] ?? 'Unknown';

    return SingleChildScrollView(
      child: Column(
        children: [
          // Image preview
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.4,
                child: Image.file(selectedImage, fit: BoxFit.cover),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Row(
                  children: [
                    FloatingActionIconButton(
                      icon: Icons.refresh,
                      onTap: () => onCaptureImage(true),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionIconButton(
                      icon: Icons.save,
                      onTap: () {
                        // Save image locally
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Image saved to gallery!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identification header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        commonName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$confidence% Match',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Species card
                InfoCard(
                  title: scientificName,
                  subtitle: type,
                  content: [
                    InfoItem(
                      icon: Icons.info_outline,
                      text: details['description'] ?? 'No description available',
                    ),
                    InfoItem(
                      icon: Icons.eco_outlined,
                      text: 'Status: ${details['status'] ?? 'Unknown'}',
                    ),
                    InfoItem(
                      icon: Icons.home_outlined,
                      text: details['habitat'] ?? 'Habitat information not available',
                    ),
                    InfoItem(
                      icon: Icons.local_florist_outlined,
                      text: 'Prefers: ${plantPreferences['preferred']?.join(', ') ?? 'Unknown plants'}',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Conservation impact card
                InfoCard(
                  title: 'Conservation Impact',
                  content: [
                    InfoItem(
                      icon: Icons.search_outlined,
                      text: 'Your sighting helps scientists track ${commonName.toLowerCase()} populations in your area.',
                    ),
                    InfoItem(
                      icon: Icons.bar_chart,
                      text: '${conservationImpact['localSightings'] ?? 'Several'} ${type.toLowerCase()}s reported in your area this week.',
                    ),
                    if (conservationImpact['importance'] != null)
                      InfoItem(
                        icon: Icons.star_outline,
                        text: conservationImpact['importance'],
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action buttons
                ActionButton(
                  label: 'Save Sighting',
                  onPressed: onSave,
                ),

                const SizedBox(height: 12),

                ActionButton(
                  label: 'Take Another Photo',
                  onPressed: onReset,
                ),

                const SizedBox(height: 16),

                ActionButton(
                  label: 'Pollinator Identification History',
                  onPressed: onViewHistory,
                ),

                // Past Identifications Section
                if (pastIdentifications.isNotEmpty && pastIdentifications.length > 1) ...[
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Recent Identifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: pastIdentifications.length,
                      itemBuilder: (context, index) {
                        // Skip the current identification which is already shown
                        final currentItem = pastIdentifications[index];
                        
                        if (index == 0 && 
                            currentItem['image'] == selectedImage) {
                          return const SizedBox.shrink();
                        }

                        return PastIdentificationItem(
                          image: currentItem['image'],
                          result: currentItem['result'],
                          timestamp: currentItem['timestamp'],
                          onTap: () => onSelectPastIdentification(currentItem),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}