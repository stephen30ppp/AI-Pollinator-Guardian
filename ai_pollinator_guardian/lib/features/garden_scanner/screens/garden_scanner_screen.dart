import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/widgets/bottom_navigation_bar.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/services/gemini_service.dart';
import 'package:ai_pollinator_guardian/services/storage_service.dart';
import 'package:ai_pollinator_guardian/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_pollinator_guardian/widgets/chat_fab.dart';
import 'package:ai_pollinator_guardian/features/chat_assistant/providers/chat_provider.dart';
import 'package:ai_pollinator_guardian/widgets/chat_panel.dart';
import 'package:provider/provider.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/providers/garden_scanner_provider.dart';
import 'package:ai_pollinator_guardian/services/garden_analyzer_service.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/widgets/score_ring.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/widgets/analysis_item.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/widgets/plant_item.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/widgets/action_item.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/widgets/image_gallery.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/widgets/action_button.dart';
import 'garden_history_screen.dart';

class GardenScannerScreen extends StatefulWidget {
  const GardenScannerScreen({super.key});

  @override
  _GardenScannerScreenState createState() => _GardenScannerScreenState();
}

class _GardenScannerScreenState extends State<GardenScannerScreen> {
  final StorageService _storageService = StorageService();
  final GeminiService _geminiService = GeminiService();
  final FirebaseService _firebaseService = FirebaseService();
  final _sheetController = DraggableScrollableController();
  late final GardenAnalyzerService _analyzerService;

  // State variables
  List<File> _gardenImages = [];
  bool _isAnalyzing = false;
  String _analysisError = '';

  // Garden analysis results
  Map<String, dynamic>? _analysis;

  @override
  void initState() {
    super.initState();
    _analyzerService = GardenAnalyzerService(_geminiService);
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _geminiService.initialize();
  }

  Future<void> _addImage(bool fromCamera) async {
    try {
      File? image = fromCamera
          ? await _storageService.takePhoto()
          : await _storageService.pickImage();

      if (image != null) {
        setState(() {
          _gardenImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding image: $e')),
      );
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a Photo'),
            onTap: () {
              Navigator.pop(context);
              _addImage(true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _addImage(false);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeGarden() async {
    if (_gardenImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one garden photo')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisError = '';
    });

    try {
      final response = await _analyzerService.analyzeGarden(_gardenImages);
      
      setState(() {
        _analysis = response;
        _isAnalyzing = false;
      });

      _onAnalysisComplete(context);
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _analysisError = 'Error analyzing garden: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing garden: $e')),
      );
    }
  }

  void _resetAnalysis() {
    setState(() {
      _gardenImages = [];
      _analysis = null;
    });
  }

  // Open chat panel method
  void _openChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sheetCtl = DraggableScrollableController();
        return DraggableScrollableSheet(
          controller: sheetCtl,
          initialChildSize: .55,
          maxChildSize: .9,
          minChildSize: .3,
          expand: false,
          builder: (innerCtx, scrollCtl) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ChatPanel(
              scrollController: scrollCtl,
              sheetCtl: sheetCtl,
            ),
          ),
        );
      },
    );
  }

  // Handle analysis completion
  void _onAnalysisComplete(BuildContext ctx) {
    if (_analysis != null) {
      // Set chat context for garden analysis
      ctx.read<ChatProvider>().seedFromContext(
        ChatContextType.garden,
        // If there are images, use the first one as visual context
        imagePath: _gardenImages.isNotEmpty ? _gardenImages.first.path : null,
      );
    }
  }

  Future<void> _saveGardenProfile() async {
    if (_analysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No analysis data to save')),
      );
      return;
    }
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving garden profile...')),
    );

    try {
      // Create a unique folder name based on timestamp
      final String folderName = 'gardens/${DateTime.now().millisecondsSinceEpoch}';
      List<String> photoUrls = [];
      
      // Upload each image and collect URLs
      if (_gardenImages.isNotEmpty) {
        photoUrls = await _storageService.uploadFiles(
          files: _gardenImages,
          folder: folderName,
          onProgress: (progress) {
            // Optional progress handling
          },
        );
      }
      
      // Prepare garden data with AI analysis and photo URLs
      final Map<String, dynamic> gardenData = {
        ..._analysis!,
        'photos': photoUrls,
        'name': 'Garden Scan ${DateTime.now().toString().substring(0, 10)}',
        'createdAt': FieldValue.serverTimestamp(),
        'userId': _firebaseService.currentUid,
      };
      
      // Save to Firestore
      final gardenRef = await _firebaseService.createDocument(
        'gardens',
        gardenData,
      );
      
      // Update user's garden list if user is signed in
      if (_firebaseService.currentUid != null) {
        await _firebaseService.updateUserProfile(
          _firebaseService.currentUid!,
          {
            'gardens': FieldValue.arrayUnion([gardenRef.id]),
          },
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Garden profile saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save garden profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update GardenScannerProvider with analysis results
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_analysis != null) {
        context.read<GardenScannerProvider>().setAnalysis(_analysis, images: _gardenImages);
      } else {
        context.read<GardenScannerProvider>().resetAnalysis();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Garden Scanner',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GardenHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          _isAnalyzing
              ? _buildLoadingView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      ImageGallery(
                        images: _gardenImages,
                        onRemoveImage: (image) {
                          setState(() {
                            _gardenImages.remove(image);
                          });
                        },
                        onAddImage: _showImageSourceDialog,
                      ),
                      const SizedBox(height: 24),
                      if (_analysis != null) ...[
                        _buildPollinatorScoreCard(),
                        const SizedBox(height: 24),
                        _buildRecommendedPlantsCard(),
                        const SizedBox(height: 24),
                        _buildActionPlanCard(),
                        const SizedBox(height: 80), // Bottom padding for FAB
                      ] else if (_analysisError.isNotEmpty) ...[
                        _buildErrorView(),
                      ] else if (_gardenImages.isNotEmpty) ...[
                        _buildAnalyzeButton(),
                        const SizedBox(height: 80),
                      ],
                    ],
                  ),
                ),
                
          // Show ChatFab when analysis is ready
          Consumer<GardenScannerProvider>(
            builder: (context, provider, _) {
              return provider.analysisReady ? const ChatFab() : const SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: PollinatorBottomNavBar(
        selectedIndex: 3, // Garden is selected
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/identify');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/map');
          }
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Garden Analysis',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Evaluate your space for pollinators',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing your garden...',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a minute',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Analysis Failed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _analysisError,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ActionButton(
            label: 'Try Again',
            onPressed: _analyzeGarden,
            isFullWidth: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return ActionButton(
      label: 'Analyze Garden',
      onPressed: _analyzeGarden,
    );
  }

  Widget _buildPollinatorScoreCard() {
    final score = _analysis!['pollinator_score'];
    final percentage = score['percentage'] as int;
    final category = score['category'] as String;
    final description = score['description'] as String;
    final analysisItems = _analysis!['analysis'] as List;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pollinator Friendliness',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on your garden photos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ScoreRing(percentage: percentage),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...analysisItems.map(
                  (item) => AnalysisItem(
                    category: item['category'] as String,
                    status: item['status'] as String,
                    description: item['description'] as String,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedPlantsCard() {
    final plants = _analysis!['recommended_plants'] as List;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Text(
                  'Recommended Plants',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...plants.map(
                  (plant) => PlantItem(
                    name: plant['name'] as String,
                    description: plant['description'] as String,
                    tags: List<String>.from(plant['tags']),
                  ),
                ),
                const SizedBox(height: 16),
                ActionButton(
                  label: 'View All Recommendations',
                  onPressed: () {
                    // Navigate to detailed recommendations
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPlanCard() {
    final actions = _analysis!['action_plan'] as List;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Text(
                  'Pollinator Action Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...actions.asMap().entries.map(
                  (entry) => ActionItem(
                    index: entry.key + 1,
                    title: entry.value['title'] as String,
                    progress: entry.value['progress'] as int,
                  ),
                ),
                const SizedBox(height: 16),
                ActionButton(
                  label: 'Save Plan to Profile',
                  onPressed: _saveGardenProfile,
                ),
                const SizedBox(height: 12),
                ActionButton(
                  label: 'Scan Garden Again',
                  isPrimary: false,
                  onPressed: _resetAnalysis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}