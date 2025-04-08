import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/services/storage_service.dart';
import 'package:ai_pollinator_guardian/services/gemini_service.dart';
import 'package:ai_pollinator_guardian/widgets/bottom_navigation_bar.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

class PollinatorIdScreen extends StatefulWidget {
  const PollinatorIdScreen({Key? key}) : super(key: key);

  @override
  _PollinatorIdScreenState createState() => _PollinatorIdScreenState();
}

class _PollinatorIdScreenState extends State<PollinatorIdScreen> {
  final StorageService _storageService = StorageService();
  final GeminiService _geminiService = GeminiService();

  // State variables
  bool _isLoading = false;
  bool _isCameraView = true; // Toggle between camera view and results view
  File? _selectedImage;
  Map<String, dynamic>? _identificationResult;
  
  // List to store past identifications during this app session
  final List<Map<String, dynamic>> _pastIdentifications = [];

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _geminiService.initialize();
  }

  Future<void> _captureImage(bool fromCamera) async {
    try {
      File? image = fromCamera
          ? await _storageService.takePhoto()
          : await _storageService.pickImage();

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _isLoading = true;
          _isCameraView = false; // Switch to results view
        });
        
        await _identifyPollinator(image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }

  Future<void> _identifyPollinator(File image) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final imageBytes = await _storageService.fileToBytes(image);
      if (imageBytes == null) {
        throw Exception('Failed to process image');
      }

      // Create a prompt for structured JSON response
      final prompt = TextPart(
        """Identify the pollinator species in this image and return your analysis as a structured JSON in the following format:
        {
          "identification": {
            "commonName": "<species common name>",
            "scientificName": "<species scientific name>",
            "confidence": <number between 0-100>,
            "type": "<bee/butterfly/beetle/etc.>"
          },
          "details": {
            "description": "<brief description of the pollinator>",
            "status": "<conservation status>",
            "habitat": "<nesting or habitat information>"
          },
          "plantPreferences": {
            "preferred": ["<plant name 1>", "<plant name 2>", "<plant name 3>"],
            "season": "<preferred blooming season>"
          },
          "conservationImpact": {
            "localSightings": <estimated number in area>,
            "importance": "<brief conservation importance note>"
          }
        }
        
        IMPORTANT: Provide only ONE identification with the highest confidence. Do NOT return a list of multiple identifications.
        
        If you cannot identify the species with reasonable confidence, provide your best guess but indicate lower confidence.
        If the image doesn't contain a pollinator, explain that in the response with a "notFound" field set to true.
        """
      );
      
      final imagePart = InlineDataPart('image/jpeg', imageBytes);
      
      // Set up JSON schema
      final schema = Schema.object(
        properties: {
          'identification': Schema.object(
            properties: {
              'commonName': Schema.string(),
              'scientificName': Schema.string(),
              'confidence': Schema.integer(),
              'type': Schema.string(),
            },
          ),
          'details': Schema.object(
            properties: {
              'description': Schema.string(),
              'status': Schema.string(),
              'habitat': Schema.string(),
            },
          ),
          'plantPreferences': Schema.object(
            properties: {
              'preferred': Schema.array(items: Schema.string()),
              'season': Schema.string(),
            },
          ),
          'conservationImpact': Schema.object(
            properties: {
              'localSightings': Schema.integer(),
              'importance': Schema.string(),
            },
          ),
          'notFound': Schema.boolean(),
        },
        optionalProperties: ['notFound'],
      );

      // Build content for the request
      final content = Content.multi([prompt, imagePart]);
      
      // Get structured response from Gemini
      final response = await _geminiService.getStructuredResponse(
        content: [content],
        schema: schema,
      );

      // Store result and add to past identifications
      setState(() {
        _identificationResult = response;
        _isLoading = false;
        
        // Add to past identifications if it's a valid identification
        if (response['notFound'] != true && 
            response['identification'] != null && 
            response['identification']['commonName'] != null) {
          _pastIdentifications.insert(0, {
            'image': _selectedImage,
            'result': response,
            'timestamp': DateTime.now(),
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _identificationResult = {
          'error': true,
          'message': 'Failed to identify pollinator: $e',
        };
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error identifying pollinator: $e')),
      );
    }
  }

  void _resetIdentification() {
    setState(() {
      _selectedImage = null;
      _identificationResult = null;
      _isCameraView = true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isCameraView ? 'Identify Pollinators' : 'Identification Results',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        leading: _isCameraView ? null : IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _resetIdentification,
        ),
      ),
      body: _isLoading 
          ? _buildLoadingView()
          : (_isCameraView ? _buildCameraView() : _buildResultsView()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/map');
        },
        backgroundColor: AppColors.primaryColor,
        child: const Text(
          '🗺️',
          style: TextStyle(fontSize: 24),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: PollinatorBottomNavBar(
        selectedIndex: 1, // Identify is selected
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/garden');
          } else if (index == 4) {
            Navigator.pushNamed(context, '/chat');
          }
        },
      ),
    );
  }
  
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_selectedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 32),
          ],
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            'Identifying pollinator...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCameraView() {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 80,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Center the pollinator in the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.zoom_in,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  // Zoom functionality would go here
                },
              ),
              GestureDetector(
                onTap: () => _captureImage(true),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.photo_library,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => _captureImage(false),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildResultsView() {
    if (_selectedImage == null) {
      return const Center(
        child: Text('No image selected'),
      );
    }

    if (_identificationResult == null) {
      return const Center(
        child: Text('No identification results available'),
      );
    }

    // Check for error
    if (_identificationResult!.containsKey('error')) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error During Identification',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _identificationResult!['message'] as String? ?? 
                'An unknown error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: _resetIdentification,
              ),
            ],
          ),
        ),
      );
    }

    // Check if no pollinator was found
    if (_identificationResult!.containsKey('notFound') && 
        _identificationResult!['notFound'] == true) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.orange[700],
              ),
              const SizedBox(height: 16),
              Text(
                'No Pollinator Detected',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We couldn\'t identify a pollinator in this image. Please try again with a clearer photo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Another Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: _resetIdentification,
              ),
            ],
          ),
        ),
      );
    }

    // Extract data from the identification result
    final identification = _identificationResult!['identification'];
    final details = _identificationResult!['details'];
    final plantPreferences = _identificationResult!['plantPreferences'];
    final conservationImpact = _identificationResult!['conservationImpact'];
    
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
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Row(
                  children: [
                    _actionButton(
                      icon: Icons.refresh,
                      onTap: () => _captureImage(true),
                    ),
                    const SizedBox(width: 12),
                    _actionButton(
                      icon: Icons.save,
                      onTap: () {
                        // Save functionality would go here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Image saved!')),
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
                _buildInfoCard(
                  title: scientificName,
                  subtitle: type,
                  content: [
                    _infoItem(
                      icon: Icons.info_outline,
                      text: details['description'] ?? 'No description available',
                    ),
                    _infoItem(
                      icon: Icons.eco_outlined,
                      text: 'Status: ${details['status'] ?? 'Unknown'}',
                    ),
                    _infoItem(
                      icon: Icons.home_outlined,
                      text: details['habitat'] ?? 'Habitat information not available',
                    ),
                    _infoItem(
                      icon: Icons.local_florist_outlined,
                      text: 'Prefers: ${plantPreferences['preferred']?.join(', ') ?? 'Unknown plants'}',
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Conservation impact card
                _buildInfoCard(
                  title: 'Conservation Impact',
                  content: [
                    _infoItem(
                      icon: Icons.search_outlined,
                      text: 'Your sighting helps scientists track ${commonName.toLowerCase()} populations in your area.',
                    ),
                    _infoItem(
                      icon: Icons.bar_chart,
                      text: '${conservationImpact['localSightings'] ?? 'Several'} ${type.toLowerCase()}s reported in your area this week.',
                    ),
                    if (conservationImpact['importance'] != null)
                      _infoItem(
                        icon: Icons.star_outline,
                        text: conservationImpact['importance'],
                      ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Save sighting functionality would go here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sighting saved!')),
                      );
                    },
                    child: const Text(
                      'Save Sighting',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Center(
                  child: GestureDetector(
                    onTap: _resetIdentification,
                    child: const Text(
                      'Take Another Photo',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Past Identifications Section
                if (_pastIdentifications.isNotEmpty && _pastIdentifications.length > 1) ...[
                  const Text(
                    'Recent Identifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pastIdentifications.length,
                      itemBuilder: (context, index) {
                        // Skip the current identification which is already shown
                        if (index == 0 && 
                            _pastIdentifications[0]['image'] == _selectedImage) {
                          return const SizedBox.shrink();
                        }
                        
                        final item = _pastIdentifications[index];
                        final File? image = item['image'];
                        final Map<String, dynamic>? result = item['result'];
                        
                        if (image == null || result == null || 
                            result['identification'] == null) {
                          return const SizedBox.shrink();
                        }
                        
                        final name = result['identification']['commonName'] ?? 'Unknown';
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImage = image;
                              _identificationResult = result;
                            });
                          },
                          child: Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    image,
                                    width: 110,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Today',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
  
  Widget _buildInfoCard({
    required String title, 
    String? subtitle, 
    required List<Widget> content
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...content,
          ],
        ),
      ),
    );
  }
  
  Widget _infoItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _actionButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}