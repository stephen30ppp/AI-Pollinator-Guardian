import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:ai_pollinator_guardian/services/gemini_service.dart';
import 'package:ai_pollinator_guardian/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PollinatorIdentifierService {
  final GeminiService _geminiService;
  final StorageService _storageService;
  
  PollinatorIdentifierService({
    required GeminiService geminiService,
    required StorageService storageService,
  }) : _geminiService = geminiService,
       _storageService = storageService;

  /// Initialize the required services
  Future<void> initialize() async {
    await _geminiService.initialize();
  }

  /// Process image and identify pollinator
  Future<Map<String, dynamic>> identifyPollinator(File image) async {
    try {
      // Convert the image to bytes in JPEG format
      final imageBytes = await _storageService.fileToBytes(
        image,
        format: 'jpeg',
      );
      
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
        """,
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

      return response;
    } catch (e) {
      debugPrint('Error identifying pollinator: $e');
      return {
        'error': true,
        'message': 'Failed to identify pollinator: $e',
      };
    }
  }

  /// Upload image to Firebase Storage
  Future<String?> uploadImageToStorage(File image, {String folder = 'pollinators'}) async {
    try {
      // Convert image to bytes
      final imageBytes = await _storageService.fileToBytes(
        image,
        format: 'jpeg',
      );
      
      if (imageBytes == null) {
        throw Exception('Failed to process image');
      }

      // Generate a unique filename based on timestamp
      final String fileName = '${DateTime.now().toIso8601String()}.jpg';
      
      // Upload to Firebase Storage
      final String downloadUrl = await _storageService.uploadBytes(
        bytes: imageBytes,
        folder: folder,
        fileName: fileName,
        metadata: SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
  
  /// Save sighting to Firestore
  Future<bool> saveSighting(Map<String, dynamic> identificationResult, String imageUrl) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Prepare sighting data
      final sightingData = {
        'pollinatorId': identificationResult['identification']['scientificName'],
        'pollinatorName': identificationResult['identification']['commonName'],
        'imageUrl': imageUrl,
        'confidence': identificationResult['identification']['confidence'],
        'timestamp': FieldValue.serverTimestamp(),
        'location': null, // Could be added in future versions with geolocation
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sightings')
          .add(sightingData);

      return true;
    } catch (e) {
      debugPrint('Error saving sighting: $e');
      return false;
    }
  }
}