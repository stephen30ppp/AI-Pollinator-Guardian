import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/widgets/bottom_navigation_bar.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/services/gemini_service.dart';
import 'package:ai_pollinator_guardian/services/storage_service.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

class GardenScannerScreen extends StatefulWidget {
  const GardenScannerScreen({Key? key}) : super(key: key);

  @override
  _GardenScannerScreenState createState() => _GardenScannerScreenState();
}

class _GardenScannerScreenState extends State<GardenScannerScreen> {
  final StorageService _storageService = StorageService();
  final GeminiService _geminiService = GeminiService();

  // State variables
  List<File> _gardenImages = [];
  bool _isAnalyzing = false;
  String _analysisError = '';

  // Garden analysis results
  Map<String, dynamic>? _analysis;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _geminiService.initialize();
  }

  Future<void> _addImage(bool fromCamera) async {
    try {
      File? image =
          fromCamera
              ? await _storageService.takePhoto()
              : await _storageService.pickImage();

      if (image != null) {
        setState(() {
          _gardenImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding image: $e')));
    }
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
      // Convert images to bytes
      List<InlineDataPart> imageParts = [];
      for (var image in _gardenImages) {
        final bytes = await image.readAsBytes();
        imageParts.add(InlineDataPart('image/jpeg', bytes));
      }

      // Create prompt for JSON response
      final prompt = TextPart(
        """Analyze these garden images and provide a detailed assessment of their pollinator-friendliness. 
        Return your analysis as a structured JSON in the following format:
        {
          "pollinator_score": {
            "percentage": <number between 0-100>,
            "category": <"Poor", "Fair", "Good", or "Excellent">,
            "description": <brief description of overall assessment>
          },
          "analysis": [
            {
              "category": <category name>,
              "status": <"good", "warning", or "bad">,
              "description": <description of finding>
            },
            ...more findings
          ],
          "recommended_plants": [
            {
              "name": <plant name>,
              "description": <brief description of benefits>,
              "tags": [<tag1>, <tag2>]
            },
            ...more plants
          ],
          "action_plan": [
            {
              "title": <action title>,
              "progress": <number between 0-100>
            },
            ...more actions
          ]
        }
        
        Focus on plant diversity, presence of native species, blooming seasons covered, and pollinator habitats.
        Recommended plants should be native and beneficial for pollinators.
        Action plan should include 3-5 concrete steps to improve the garden for pollinators.
        """,
      );

      // Prepare the content with text and images
      final contentParts = [prompt, ...imageParts];
      final content = Content.multi(contentParts);

      // Set up JSON schema
      final schema = Schema(
        SchemaType.object,
        properties: {
          'pollinator_score': Schema(
            SchemaType.object,
            properties: {
              'percentage': Schema(SchemaType.integer),
              'category': Schema(SchemaType.string),
              'description': Schema(SchemaType.string),
            },
          ),
          'analysis': Schema(
            SchemaType.array,
            items: Schema(
              SchemaType.object,
              properties: {
                'category': Schema(SchemaType.string),
                'status': Schema(SchemaType.string),
                'description': Schema(SchemaType.string),
              },
            ),
          ),
          'recommended_plants': Schema(
            SchemaType.array,
            items: Schema(
              SchemaType.object,
              properties: {
                'name': Schema(SchemaType.string),
                'description': Schema(SchemaType.string),
                'tags': Schema(
                  SchemaType.array,
                  items: Schema(SchemaType.string),
                ),
              },
            ),
          ),
          'action_plan': Schema(
            SchemaType.array,
            items: Schema(
              SchemaType.object,
              properties: {
                'title': Schema(SchemaType.string),
                'progress': Schema(SchemaType.integer),
              },
            ),
          ),
        },
      );

      // Get structured response
      final response = await _geminiService.getStructuredResponse(
        content: [content],
        schema: schema,
      );

      setState(() {
        _analysis = response;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _analysisError = 'Error analyzing garden: $e';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error analyzing garden: $e')));
    }
  }

  void _resetAnalysis() {
    setState(() {
      _gardenImages = [];
      _analysis = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body:
          _isAnalyzing
              ? _buildLoadingView()
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildImageGallery(),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/map');
        },
        backgroundColor: AppColors.primaryColor,
        child: const Text('🗺️', style: TextStyle(fontSize: 24)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: PollinatorBottomNavBar(
        selectedIndex: 3, // Garden is selected
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/identify');
          } else if (index == 4) {
            Navigator.pushNamed(context, '/chat');
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

  Widget _buildImageGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._gardenImages.map((image) => _buildImageThumbnail(image)),
              _buildAddImageButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(File image) {
    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(image, fit: BoxFit.cover),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _gardenImages.remove(image);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder:
              (context) => Column(
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
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'Add Photo',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _analyzeGarden,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Analyze Garden',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
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
          ElevatedButton(
            onPressed: _analyzeGarden,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
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
                    _buildScoreRing(percentage),
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
                  (item) => _buildAnalysisItem(
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

  Widget _buildScoreRing(int percentage) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          startAngle: 3 * 3.14 / 2,
          endAngle: 7 * 3.14 / 2,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor,
            Colors.grey[300]!,
            Colors.grey[300]!,
          ],
          stops: [0.0, percentage / 100, percentage / 100, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Center(
            child: Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisItem({
    required String category,
    required String status,
    required String description,
  }) {
    IconData icon;
    Color color;

    switch (status) {
      case 'good':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'warning':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case 'bad':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        icon = Icons.info;
        color = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                  (plant) => _buildPlantItem(
                    name: plant['name'] as String,
                    description: plant['description'] as String,
                    tags: List<String>.from(plant['tags']),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
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

  Widget _buildPlantItem({
    required String name,
    required String description,
    required List<String> tags,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
            child: const Center(
              child: Icon(Icons.local_florist, size: 32, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.map((tag) => _buildPlantTag(tag)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: TextStyle(fontSize: 12, color: Colors.green[700]),
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
                  (entry) => _buildActionItem(
                    index: entry.key + 1,
                    title: entry.value['title'] as String,
                    progress: entry.value['progress'] as int,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  label: 'Save Plan to Profile',
                  onPressed: () {
                    // Save action plan logic
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
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

  Widget _buildActionItem({
    required int index,
    required String title,
    required int progress,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width:
                            (MediaQuery.of(context).size.width - 100) *
                            progress /
                            100,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = true,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isPrimary ? AppColors.primaryColor : Colors.grey[200],
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isPrimary ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
