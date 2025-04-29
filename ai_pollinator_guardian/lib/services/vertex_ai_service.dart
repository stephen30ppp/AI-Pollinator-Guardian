import 'package:firebase_vertexai/firebase_vertexai.dart';

class VertexAIService {
  final GenerativeModel model;

  VertexAIService()
    : model = FirebaseVertexAI.instance.generativeModel('gemini-2.0-flash');

  Future<String?> generateText(String prompt) async {
    try {
      final response = await model.generateContent(prompt);
      return response.text; // Return the generated text
    } catch (e) {
      print("Error in Vertex AI: $e");
      return null;
    }
  }
}
