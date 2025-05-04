import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/services/firebase_service.dart';
import 'package:ai_pollinator_guardian/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/widgets/garden_card.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/widgets/garden_overview_card.dart';

class GardenHistoryScreen extends StatefulWidget {
  GardenHistoryScreen({super.key});

  @override
  State<GardenHistoryScreen> createState() => _GardenHistoryScreenState();
}

class _GardenHistoryScreenState extends State<GardenHistoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final StorageService _storageService = StorageService();
  
  // Selection state
  bool _isSelectMode = false;
  final Set<String> _selectedGardens = {};
  bool _isDeleting = false;
  
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

  // Show garden details in a bottom sheet
  void _showGardenDetails(BuildContext context, Map<String, dynamic> garden) {
    // Don't show details when in selection mode
    if (_isSelectMode) {
      _toggleSelection(garden['id']);
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildDetailSheet(context, garden),
    );
  }

  // Build the detail sheet content
  Widget _buildDetailSheet(BuildContext context, Map<String, dynamic> garden) {
    String createdAt = 'Unknown Date';

    if (garden['createdAt'] != null) {
      try {
        // Handle both string dates and Timestamps
        if (garden['createdAt'] is String) {
          createdAt = _formatDate(DateTime.parse(garden['createdAt']));
        } else {
          // Assuming Timestamp has toDate() method
          createdAt = _formatDate(garden['createdAt'].toDate());
        }
      } catch (e) {
        debugPrint('Error parsing createdAt: $e');
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          
          // Garden name and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  garden['name'] ?? 'Unnamed Garden',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              Text(
                createdAt,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Scrollable garden details
          Expanded(
            child: SingleChildScrollView(
              child: GardenCard(garden: garden),
            ),
          ),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Delete button
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Add the garden to selected and trigger delete
                  setState(() {
                    _selectedGardens.clear();
                    _selectedGardens.add(garden['id']);
                  });
                  _showDeleteConfirmation();
                },
                icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                label: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Share functionality could be added here
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

  // Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) {
        _selectedGardens.clear();
      }
    });
  }

  // Toggle selection of a garden
  void _toggleSelection(String gardenId) {
    setState(() {
      if (_selectedGardens.contains(gardenId)) {
        _selectedGardens.remove(gardenId);
      } else {
        _selectedGardens.add(gardenId);
      }
      
      // Exit selection mode if nothing is selected
      if (_selectedGardens.isEmpty && _isSelectMode) {
        _isSelectMode = false;
      }
    });
  }

  // Select all gardens
  void _selectAll(List<Map<String, dynamic>> gardens) {
    setState(() {
      if (_selectedGardens.length == gardens.length) {
        // If all are selected, deselect all
        _selectedGardens.clear();
      } else {
        // Otherwise select all
        _selectedGardens.clear();
        for (var garden in gardens) {
          _selectedGardens.add(garden['id']);
        }
      }
    });
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteConfirmation() async {
    if (_selectedGardens.isEmpty) return;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _selectedGardens.length == 1
                ? 'Delete Garden'
                : 'Delete ${_selectedGardens.length} Gardens',
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  _selectedGardens.length == 1
                      ? 'Are you sure you want to delete this garden? This action cannot be undone.'
                      : 'Are you sure you want to delete these ${_selectedGardens.length} gardens? This action cannot be undone.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red[700]),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSelectedGardens();
              },
            ),
          ],
        );
      },
    );
  }

  // Delete selected gardens
  Future<void> _deleteSelectedGardens() async {
    if (_selectedGardens.isEmpty) return;
    
    setState(() {
      _isDeleting = true;
    });
    
    try {
      // Store IDs to delete from user profile
      final List<String> gardensToRemove = List.from(_selectedGardens);
      
      // For each selected garden
      for (String gardenId in gardensToRemove) {
        try {
          // Get garden data for photo URLs
          final gardenDoc = await FirebaseFirestore.instance
              .collection('gardens')
              .doc(gardenId)
              .get();
          
          if (gardenDoc.exists) {
            final Map<String, dynamic> data = gardenDoc.data()!;
            
            // Delete photos from storage if any
            if (data.containsKey('photos')) {
              final List<dynamic> photos = data['photos'];
              for (String photoUrl in List<String>.from(photos)) {
                try {
                  // Get the storage reference from the URL
                  final ref = _storageService.getStorageRefFromUrl(photoUrl);
                  if (ref != null) {
                    await _storageService.deleteFileOrFolder(ref);
                  }
                } catch (e) {
                  debugPrint('Error deleting photo: $e');
                }
              }
            }
            
            // Delete the garden document
            await FirebaseFirestore.instance
                .collection('gardens')
                .doc(gardenId)
                .delete();
            
            // Remove from user's gardens array
            if (_firebaseService.currentUid != null) {
              await _firebaseService.updateUserProfile(
                _firebaseService.currentUid!,
                {
                  'gardens': FieldValue.arrayRemove([gardenId]),
                },
              );
            }
          }
        } catch (e) {
          debugPrint('Error deleting garden $gardenId: $e');
        }
      }
      
      // Clear selection and exit selection mode
      setState(() {
        _selectedGardens.clear();
        _isSelectMode = false;
        _isDeleting = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            gardensToRemove.length == 1
                ? 'Garden deleted successfully'
                : '${gardensToRemove.length} gardens deleted successfully',
          ),
          backgroundColor: Colors.green[700],
        ),
      );
      
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting gardens: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectMode
            ? Text(
                '${_selectedGardens.length} Selected',
                style: const TextStyle(color: Colors.white),
              )
            : const Text(
                'My Garden History',
                style: TextStyle(color: Colors.white),
              ),
        backgroundColor: _isSelectMode ? Colors.grey[800] : AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _isSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
        actions: [
          if (_isSelectMode) ...[
            // Select all button
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select All',
              onPressed: () async {
                final gardens = await _getGardenProfilesByUser();
                _selectAll(gardens);
              },
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Selected',
              onPressed: _selectedGardens.isNotEmpty
                  ? _showDeleteConfirmation
                  : null,
            ),
          ] else ...[
            // Enter selection mode button
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select Gardens',
              onPressed: _toggleSelectionMode,
            ),
            // Filter button
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter Gardens',
              onPressed: () {
                // Filter functionality to be implemented
              },
            ),
          ],
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
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
                          setState(() {});
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
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed('/garden'),
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Scan Garden'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
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
                  final String gardenId = garden['id'];
                  final bool isSelected = _selectedGardens.contains(gardenId);
                  
                  // Use the enhanced garden overview card with selection state
                  return GardenOverviewCard(
                    garden: garden,
                    isSelectable: _isSelectMode,
                    isSelected: isSelected,
                    onTap: () => _showGardenDetails(context, garden),
                    onLongPress: () {
                      // Start selection mode if not already in it
                      if (!_isSelectMode) {
                        setState(() {
                          _isSelectMode = true;
                          _selectedGardens.add(gardenId);
                        });
                      } else {
                        _toggleSelection(gardenId);
                      }
                    },
                    onSelect: _isSelectMode ? () => _toggleSelection(gardenId) : null,
                  );
                },
              );
            },
          ),
          
          // Loading overlay
          if (_isDeleting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Deleting gardens...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
        onPressed: () => Navigator.of(context).pushNamed('/garden'),
        tooltip: 'Scan New Garden',
      ),
    );
  }
}