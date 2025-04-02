import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final String baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  late final String apiKey;
  
  GeminiService() {
    apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      print('WARNING: GEMINI_API_KEY is not set in .env file');
    }
  }

  // Text-only prompt to Gemini
  Future<String?> generateTextResponse(String prompt) async {
    try {
      final url = '$baseUrl/models/gemini-pro:generateContent?key=$apiKey';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return _extractTextFromResponse(data);
      } else {
        print('Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error generating text response: $e');
      return null;
    }
  }

  // Image analysis with Gemini Vision
  Future<String?> analyzeImage(Uint8List imageBytes, String prompt) async {
    try {
      final url = '$baseUrl/models/gemini-pro-vision:generateContent?key=$apiKey';
      
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return _extractTextFromResponse(data);
      } else {
        print('Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error analyzing image: $e');
      return null;
    }
  }

  // Helper method to extract text from Gemini API response
  String? _extractTextFromResponse(Map<String, dynamic> data) {
    try {
      final candidates = data['candidates'] as List;
      if (candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List;
        if (parts.isNotEmpty && parts[0].containsKey('text')) {
          return parts[0]['text'] as String;
        }
      }
      return null;
    } catch (e) {
      print('Error extracting text from response: $e');
      return null;
    }
  }

  // Methods for specific application features

  // Identify pollinator from image
  Future<Map<String, dynamic>?> identifyPollinator(Uint8List imageBytes) async {
    const prompt = '''
    Identify the pollinator in this image. 
    If you see a bee, butterfly, or other pollinating insect/animal, provide the following information in JSON format:
    {
      "identified": true,
      "commonName": "name of the pollinator",
      "scientificName": "scientific name if possible",
      "type": "bee/butterfly/beetle/other",
      "confidence": 0.XX (between 0-1),
      "description": "brief description",
      "conservationStatus": "status if known",
      "preferredPlants": ["plant1", "plant2"],
      "facts": ["interesting fact 1", "interesting fact 2"]
    }
    
    If no pollinator is clearly visible, respond with:
    {
      "identified": false,
      "message": "No pollinator detected in the image."
    }
    ''';

    final response = await analyzeImage(imageBytes, prompt);
    if (response != null) {
      try {
        // Extract JSON from the response (the model might wrap it in text)
        final jsonRegExp = RegExp(r'{[\s\S]*}');
        final match = jsonRegExp.firstMatch(response);
        if (match != null) {
          final jsonString = match.group(0);
          return json.decode(jsonString!) as Map<String, dynamic>;
        }
      } catch (e) {
        print('Error parsing JSON from response: $e');
      }
    }
    return null;
  }

  // Analyze garden from image
  Future<Map<String, dynamic>?> analyzeGarden(List<Uint8List> imageBytes) async {
    // Handle just the first image for simplicity in this prototype
    if (imageBytes.isEmpty) return null;
    
    const prompt = '''
    Analyze this garden image for pollinator-friendliness. 
    Evaluate plant diversity, presence of flowering plants, native species, etc.
    Return results in JSON format:
    {
      "pollinatorScore": 0.XX (between 0-1),
      "analysisResults": {
        "plantDiversity": true/false,
        "nativePlants": true/false,
        "bloomingSeasons": true/false,
        "pollinatorHabitat": true/false
      },
      "summary": "brief analysis",
      "recommendations": [
        {
          "name": "plant name",
          "description": "why this plant would help",
          "tags": ["native", "bee-friendly", etc.]
        }
      ]
    }
    ''';

    final response = await analyzeImage(imageBytes[0], prompt);
    if (response != null) {
      try {
        // Extract JSON from the response
        final jsonRegExp = RegExp(r'{[\s\S]*}');
        final match = jsonRegExp.firstMatch(response);
        if (match != null) {
          final jsonString = match.group(0);
          return json.decode(jsonString!) as Map<String, dynamic>;
        }
      } catch (e) {
        print('Error parsing JSON from response: $e');
      }
    }
    return null;
  }

  // Get chatbot response
  Future<Map<String, dynamic>?> getChatbotResponse(
    String message, 
    List<Map<String, String>> chatHistory
  ) async {
    // Format chat history for context
    final historyText = chatHistory
        .map((msg) => "${msg['role']}: ${msg['content']}")
        .join('\n');
    
    final prompt = '''
    You are a pollinator gardening assistant named "Bee Guide". 
    Your role is to help users identify pollinators, suggest plants, and provide care tips.
    Be friendly, informative, and concise. Focus on being helpful with practical advice.
    
    Chat history:
    $historyText
    
    User: $message
    
    Respond with JSON:
    {
      "response": "your helpful response",
      "suggestions": ["suggestion 1", "suggestion 2"],
      "resources": [
        {
          "title": "resource title (if relevant)",
          "content": "brief description",
          "linkUrl": "url if applicable"
        }
      ]
    }
    ''';

    final response = await generateTextResponse(prompt);
    if (response != null) {
      try {
        // Extract JSON from the response
        final jsonRegExp = RegExp(r'{[\s\S]*}');
        final match = jsonRegExp.firstMatch(response);
        if (match != null) {
          final jsonString = match.group(0);
          return json.decode(jsonString!) as Map<String, dynamic>;
        }
      } catch (e) {
        print('Error parsing JSON from response: $e');
      }
    }
    return null;
  }
}