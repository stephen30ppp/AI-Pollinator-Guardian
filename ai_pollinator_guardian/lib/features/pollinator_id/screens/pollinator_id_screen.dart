import 'dart:io';
import 'package:ai_pollinator_guardian/widgets/chat_panel.dart';
import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/widgets/bottom_navigation_bar.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/services/storage_service.dart';
import 'package:ai_pollinator_guardian/services/gemini_service.dart';
import 'package:ai_pollinator_guardian/widgets/chat_fab.dart';
import 'package:ai_pollinator_guardian/features/chat_assistant/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:ai_pollinator_guardian/features/pollinator_id/providers/identify_provider.dart';
import 'package:ai_pollinator_guardian/services/pollinator_identifier_service.dart';
import 'package:ai_pollinator_guardian/features/pollinator_id/widgets/loading_view.dart';
import 'package:ai_pollinator_guardian/features/pollinator_id/widgets/camera_view.dart';
import 'package:ai_pollinator_guardian/features/pollinator_id/widgets/error_view.dart';
import 'package:ai_pollinator_guardian/features/pollinator_id/widgets/not_found_view.dart';
import 'package:ai_pollinator_guardian/features/pollinator_id/widgets/result_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PollinatorIdScreen extends StatefulWidget {
  const PollinatorIdScreen({super.key});

  @override
  _PollinatorIdScreenState createState() => _PollinatorIdScreenState();
}

class _PollinatorIdScreenState extends State<PollinatorIdScreen> {
  late final StorageService _storageService;
  late final GeminiService _geminiService;
  late final PollinatorIdentifierService _identifierService;
  final _sheetController = DraggableScrollableController();

  // State variables
  bool _isLoading = false;
  bool _isCameraView = true;
  File? _selectedImage;
  Map<String, dynamic>? _identificationResult;

  // List to store past identifications during this app session
  final List<Map<String, dynamic>> _pastIdentifications = [];

  @override
  void initState() {
    super.initState();
    _storageService = StorageService();
    _geminiService = GeminiService();
    _identifierService = PollinatorIdentifierService(
      geminiService: _geminiService,
      storageService: _storageService,
    );
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _identifierService.initialize();
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
          _isCameraView = false;
        });

        // Upload the image to Firebase Storage
        final downloadUrl = await _identifierService.uploadImageToStorage(image);
        if (downloadUrl == null) {
          throw Exception('Failed to upload image to Firebase Storage');
        }

        // Proceed with pollinator identification
        await _identifyPollinator(image);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }

  Future<void> _identifyPollinator(File image) async {
    try {
      // Identify the pollinator
      final response = await _identifierService.identifyPollinator(image);

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

      // Update the chat context
      _onIdentifyComplete(context);
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

  // Method to handle a past identification selection
  void _selectPastIdentification(Map<String, dynamic> item) {
    setState(() {
      _selectedImage = item['image'];
      _identificationResult = item['result'];
    });
  }

  // Method to open chat panel
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

  // Method to handle identification completion
  void _onIdentifyComplete(BuildContext ctx) {
    if (_identificationResult != null &&
        _identificationResult!['identification'] != null &&
        _selectedImage != null) {
      
      // Get name from identification result
      final commonName = _identificationResult!['identification']['commonName'] ?? 'Unknown Species';
      
      // Set chat context
      ctx.read<ChatProvider>().seedFromContext(
        ChatContextType.identify,
        label: commonName,
        imagePath: _selectedImage!.path,
      );
    }
  }

  // Save sighting to Firebase
  Future<void> _saveSighting() async {
    if (_selectedImage == null || _identificationResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid identification to save')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving sighting...')),
      );

      // First upload the image
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Upload to dedicated user folder
      final String folderPath = 'users/$userId/sightings';
      final String? imageUrl = await _identifierService.uploadImageToStorage(
        _selectedImage!,
        folder: folderPath,
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Save the sighting data
      final success = await _identifierService.saveSighting(
        _identificationResult!,
        imageUrl,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sighting saved successfully!')),
        );
      } else {
        throw Exception('Failed to save sighting data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving sighting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update identification result in IdentifyProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_identificationResult != null && _selectedImage != null) {
        context.read<IdentifyProvider>().setResult(_identificationResult, image: _selectedImage);
      } else if (_identificationResult == null) {
        context.read<IdentifyProvider>().resetResult();
      }
    });

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
        leading: _isCameraView
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _resetIdentification,
              ),
      ),
      body: Stack(
        children: [
          // Main content
          _buildMainContent(),
          
          // ChatFab overlay - only show when we have a valid identification
          Consumer<IdentifyProvider>(
            builder: (context, provider, _) {
              return provider.analysisReady ? const ChatFab() : const SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: PollinatorBottomNavBar(
        selectedIndex: 1, // Identify is selected
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/map');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/garden');
          }
        },
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return IdentificationLoadingView(selectedImage: _selectedImage);
    }
    
    if (_isCameraView) {
      return CameraView(
        onCapturePhoto: () => _captureImage(true),
        onGalleryPick: () => _captureImage(false),
      );
    }
    
    // Handle various states in results view
    if (_selectedImage == null) {
      return const Center(child: Text('No image selected'));
    }

    if (_identificationResult == null) {
      return const Center(child: Text('No identification results available'));
    }

    // Check for error
    if (_identificationResult!.containsKey('error')) {
      return ErrorView(
        errorMessage: _identificationResult!['message'] as String? ?? 'An unknown error occurred',
        onTryAgain: _resetIdentification,
      );
    }

    // Check if no pollinator was found
    if (_identificationResult!.containsKey('notFound') &&
        _identificationResult!['notFound'] == true) {
      return NotFoundView(
        onTakeAnotherPhoto: _resetIdentification,
      );
    }

    // Show successful identification results
    return IdentificationResultView(
      selectedImage: _selectedImage!,
      identificationResult: _identificationResult!,
      pastIdentifications: _pastIdentifications,
      onReset: _resetIdentification,
      onSave: _saveSighting,
      onViewHistory: () => Navigator.pushNamed(context, '/history'),
      onSelectPastIdentification: _selectPastIdentification,
      onCaptureImage: _captureImage,
    );
  }
}