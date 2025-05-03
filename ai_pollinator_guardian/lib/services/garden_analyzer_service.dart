import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:ai_pollinator_guardian/services/gemini_service.dart';

class GardenAnalyzerService {
  final GeminiService _geminiService;
  
  GardenAnalyzerService(this._geminiService);
  
  /// Analyzes garden images and returns a structured analysis
  Future<Map<String, dynamic>> analyzeGarden(List<File> gardenImages) async {
    if (gardenImages.isEmpty) {
      throw Exception('No garden images provided for analysis');
    }

    // Convert images to bytes
    List<InlineDataPart> imageParts = [];
    for (var image in gardenImages) {
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
    try {
      final response = await _geminiService.getStructuredResponse(
        content: [content],
        schema: schema,
      );
      
      return response;
    } catch (e) {
      debugPrint('Error analyzing garden: $e');
      throw Exception('Failed to analyze garden: $e');
    }
  }
}