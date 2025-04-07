import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:ai_pollinator_guardian/services/storage_service.dart';
import 'dart:io';
import 'package:ai_pollinator_guardian/firebase_options.dart';

class GardenScannerPage extends StatefulWidget {
  @override
  _GardenScannerPageState createState() => _GardenScannerPageState();
}

class _GardenScannerPageState extends State<GardenScannerPage> {
  final StorageService _storageService = StorageService();
  late final GenerativeModel _model;
  List<Map<String, dynamic>> pastScans = [];
  bool isLoading = false;
  String currentAnalysis = ""; // Stores streaming response

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.0-flash',
    );
  }

  Future<void> _scanGarden(bool fromCamera) async {
    setState(() {
      isLoading = true;
      currentAnalysis = "Analyzing...";
    });

    File? image =
        fromCamera
            ? await _storageService.takePhoto()
            : await _storageService.pickImage();

    if (image != null) {
      Uint8List? imageBytes = await _storageService.fileToBytes(image);
      if (imageBytes != null) {
        final prompt = TextPart(
          "Analyze this image and provide plant diversity insights, pollinator-friendliness score, and native plant recommendations.",
        );
        final imagePart = InlineDataPart('image/jpeg', imageBytes);

        try {
          final responseStream = _model.generateContentStream([
            Content.multi([prompt, imagePart]),
          ]);

          // Stream response updates in real time
          setState(() {
            currentAnalysis = "";
          });

          await for (final chunk in responseStream) {
            setState(() {
              currentAnalysis += chunk.text ?? "";
            });
          }

          // Store final result
          setState(() {
            pastScans.insert(0, {"summary": currentAnalysis});
          });
        } catch (e) {
          print("Error with Vertex AI: $e");
          setState(() {
            currentAnalysis = "Error processing image.";
          });
        }
      }
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Garden Scanner')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: pastScans.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: ListTile(
                      title: Text("Live Analysis:"),
                      subtitle: Text(
                        currentAnalysis.isNotEmpty
                            ? currentAnalysis
                            : "No analysis yet.",
                      ),
                    ),
                  );
                }
                final scan = pastScans[index - 1];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text("Previous Analysis:"),
                    subtitle: Text(scan['summary'] ?? "No details available"),
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
                label: Text("Take Photo"),
                onPressed: () => _scanGarden(true),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.photo_library),
                label: Text("Select from Gallery"),
                onPressed: () => _scanGarden(false),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}