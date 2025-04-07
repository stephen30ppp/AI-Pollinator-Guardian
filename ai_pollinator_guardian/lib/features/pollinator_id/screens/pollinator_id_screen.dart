import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:ai_pollinator_guardian/services/storage_service.dart';
import 'package:ai_pollinator_guardian/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:ai_pollinator_guardian/firebase_options.dart';
import 'package:ai_pollinator_guardian/models/sighting_model.dart';
import 'package:ai_pollinator_guardian/models/pollinator_model.dart';

class PollinatorIdScreen extends StatefulWidget {
  const PollinatorIdScreen({super.key});

  @override
  _PollinatorIdScreenState createState() => _PollinatorIdScreenState();
}

class _PollinatorIdScreenState extends State<PollinatorIdScreen> {
  final StorageService _storageService = StorageService();
  final FirebaseService _firebaseService = FirebaseService();
  late final GenerativeModel _model;

  bool isLoading = false;
  String currentAnalysis = "";
  List<Map<String, dynamic>> pastIdentifications = [];
  File? selectedImage; // Track the selected image

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _loadPreviousIdentifications();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.0-flash',
    );
  }

  Future<void> _loadPreviousIdentifications() async {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) return;

    final previousSightings = await _firebaseService.getUserSightings(userId);
    setState(() {
      pastIdentifications = previousSightings.map((sighting) => {
        "species": sighting.pollinatorName,
        "imageUrl": sighting.imageUrl,
      }).toList();
    });
  }

  Future<void> _identifyPollinator(bool fromCamera) async {
    setState(() {
      isLoading = true;
      currentAnalysis = "Analyzing...";
    });

    File? image = fromCamera
        ? await _storageService.takePhoto()
        : await _storageService.pickImage();

    if (image == null) {
      setState(() {
        isLoading = false;
        currentAnalysis = "No image was selected.";
      });
      return;
    }

    setState(() {
      selectedImage = image; // Store the selected image
    });

    Uint8List? imageBytes = await _storageService.fileToBytes(image);
    if (imageBytes == null || imageBytes.isEmpty) {
      setState(() {
        isLoading = false;
        currentAnalysis = "Failed to process image.";
      });
      return;
    }

    final imageUrl = await _firebaseService.uploadImage(
      'pollinators/${DateTime.now().millisecondsSinceEpoch}.jpg',
      imageBytes,
    );

    final prompt = TextPart(
      "Identify the pollinator species in this image. Provide the following details:\n"
      "- Common name\n"
      "- Scientific name\n"
      "- Short description\n"
      "- Type (bee, butterfly, beetle, etc.)\n"
      "- List of preferred plants\n"
      "- Conservation status\n"
      "- Additional relevant information",
    );
    final imagePart = InlineDataPart('image/jpeg', imageBytes);

    try {
      final responseStream = _model.generateContentStream([
        Content.multi([prompt, imagePart]),
      ]);

      String apiResponse = "";
      await for (final chunk in responseStream) {
        apiResponse += chunk.text ?? "";
        setState(() {
          currentAnalysis = apiResponse;
        });
      }

      final parsedData = parsePollinatorResponse(apiResponse);

      final pollinator = PollinatorModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        commonName: parsedData['commonName'] ?? "Unknown",
        scientificName: parsedData['scientificName'] ?? "Unknown",
        description: parsedData['description'] ?? "No description available",
        imageUrl: imageUrl,
        type: parsedData['type'] ?? "Other",
        preferredPlants: List<String>.from(parsedData['preferredPlants'] ?? []),
        conservationStatus: parsedData['conservationStatus'] ?? "Unknown",
        additionalInfo: parsedData['additionalInfo'] ?? {},
      );

      await _firebaseService.saveSighting(
        SightingModel(
          id: pollinator.id,
          userId: _firebaseService.currentUser?.uid ?? "",
          pollinatorId: pollinator.id,
          pollinatorName: pollinator.commonName,
          imageUrl: pollinator.imageUrl,
          location: GeoPoint(0, 0),
          confidence: 1.0,
          timestamp: DateTime.now(),
        ),
      );

      setState(() {
        pastIdentifications.insert(0, {
          "species": pollinator.commonName,
          "imageUrl": pollinator.imageUrl,
        });
      });
    } catch (e) {
      print("Error with Vertex AI: $e");
      setState(() {
        currentAnalysis = "Error processing image.";
      });
    }

    setState(() => isLoading = false);
  }

  Map<String, dynamic> parsePollinatorResponse(String response) {
    final Map<String, dynamic> result = {};

    RegExpMatch? match;
    match = RegExp(r"Common name: (.+)").firstMatch(response);
    result['commonName'] = match?.group(1)?.trim() ?? "Unknown";

    match = RegExp(r"Scientific name: (.+)").firstMatch(response);
    result['scientificName'] = match?.group(1)?.trim() ?? "Unknown";

    match = RegExp(r"Short description: (.+)").firstMatch(response);
    result['description'] = match?.group(1)?.trim() ?? "No description available";

    match = RegExp(r"Type: (.+)").firstMatch(response);
    result['type'] = match?.group(1)?.trim() ?? "Other";

    match = RegExp(r"Preferred plants: (.+)").firstMatch(response);
    result['preferredPlants'] = match?.group(1)?.split(",").map((e) => e.trim()).toList() ?? [];

    match = RegExp(r"Conservation status: (.+)").firstMatch(response);
    result['conservationStatus'] = match?.group(1)?.trim() ?? "Unknown";

    result['additionalInfo'] = {"Raw Response": response};

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pollinator Identification')),
      body: Column(
        children: [
          // Show selected image preview if available
          if (selectedImage != null)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Image.file(
                selectedImage!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: pastIdentifications.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: ListTile(
                      title: Text("Current Identification:"),
                      subtitle: Text(currentAnalysis.isNotEmpty ? currentAnalysis : "No identification yet."),
                    ),
                  );
                }

                final identification = pastIdentifications[index - 1];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    leading: identification['imageUrl'] != null
                        ? Image.network(identification['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                        : Icon(Icons.image_not_supported),
                    title: Text(identification['species'] ?? "Unknown Species"),
                  ),
                );
              },
            ),
          ),
          if (isLoading) CircularProgressIndicator(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.camera_alt),
                label: Text("Capture Image"),
                onPressed: () => _identifyPollinator(true),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.photo_library),
                label: Text("Select from Gallery"),
                onPressed: () => _identifyPollinator(false),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}