import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/models/chat_message_model.dart';
import 'package:uuid/uuid.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  late GenerativeModel _model;
  ChatSession? _chatSession;
  final uuid = Uuid();
  bool _isInitialized = false;

  // Initialize the Gemini service with the appropriate model
  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent re-initialization
    
    debugPrint('Initializing GeminiService...');
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.0-flash',
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );

    debugPrint('Generative model initialized with gemini-2.0-flash.');

    // Start a new chat session
    await _startNewChat();
    _isInitialized = true;
  }

  Future<void> _startNewChat() async {
    debugPrint('Starting new chat session...');
    // Create system instructions as the first message in history
    const systemInstructionText =
        "You are a helpful pollinator gardening assistant called 'Bee Guide'. "
        "Your primary goal is to help users protect and support pollinators. "
        "You can help with identifying pollinators, suggesting plants that attract specific pollinators, "
        "providing gardening tips, explaining pollinator behavior, and answering questions about "
        "conservation. Keep your responses friendly, concise, and focused on helping users create "
        "pollinator-friendly environments. Include specific, actionable advice when possible. "
        "For plant recommendations, focus on native plants when appropriate, and explain why they're beneficial.";

    // Create initial history with system instructions
    final systemInstruction = Content.text(systemInstructionText);

    // Start a chat session with the system instruction in the history
    _chatSession = _model.startChat(history: [systemInstruction]);
    debugPrint('Chat session started with system instructions.');
  }

  // Start a new chat session
  Future<ChatMessageModel> startNewChat() async {
    debugPrint('Restarting chat session via startNewChat()...');
    await _startNewChat();

    final welcomeMessageText =
        "Hello! I'm your pollinator gardening assistant. I can help with identifying pollinators, suggesting plants, and providing care tips. What would you like to know today?";
    debugPrint('Returning welcome message: $welcomeMessageText');

    return ChatMessageModel(
      id: uuid.v4(),
      text: welcomeMessageText,
      isUser: false,
      timestamp: DateTime.now(),
      suggestions: [
        ChatSuggestion(text: "How to attract bees?"),
        ChatSuggestion(text: "Best plants for butterflies"),
        ChatSuggestion(text: "Pollinator garden tips"),
        ChatSuggestion(text: "Identify a pollinator"),
      ],
    );
  }

  // Send a message to the chat
  Future<ChatMessageModel> sendMessage(String message) async {
    debugPrint('sendMessage called with message: $message');
    if (_chatSession == null) {
      debugPrint('No active chat session found, starting a new one.');
      await _startNewChat();
    }

    try {
      final userContent = Content.text(message);
      debugPrint('Sending user message to chat session...');
      final response = await _chatSession!.sendMessage(userContent);

      debugPrint('Received response: ${response.text}');

      // Process the response to extract suggestions and resources (if any)
      final List<ChatSuggestion> suggestions = [];
      final List<ChatResource> resources = [];

      // Simple logic to look for plant recommendations in the response
      if (response.text != null &&
          (response.text!.contains("recommend") ||
              response.text!.contains("plant") ||
              response.text!.contains("garden"))) {
        debugPrint(
          'Response contains keywords related to plants or garden; adding suggestions.',
        );
        // Add some follow-up suggestions
        suggestions.add(ChatSuggestion(text: "More plant recommendations"));
        suggestions.add(ChatSuggestion(text: "How to care for these plants"));
      }

      return ChatMessageModel(
        id: uuid.v4(),
        text: response.text ?? "I'm sorry, I couldn't generate a response.",
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: suggestions,
        resources: resources,
      );
    } catch (e) {
      debugPrint('Error sending message to Gemini: $e');
      return ChatMessageModel(
        id: uuid.v4(),
        text: "I'm sorry, I encountered an error. Please try again.",
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  // Send a message and stream the response for real-time updates
  Stream<ChatMessageModel> sendMessageStream(
    String message, {
    String? botMessageId,
  }) async* {
    if (_chatSession == null) {
      await _startNewChat();
    }

    try {
      final userContent = Content.text(message);
      final responseStream = _chatSession!.sendMessageStream(userContent);

      // Use the ID passed in from ChatProvider, so the UI can match it
      final messageId = botMessageId ?? uuid.v4();
      String fullText = '';

      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          fullText += chunk.text!;
          yield ChatMessageModel(
            id: messageId,
            text: fullText,
            isUser: false,
            timestamp: DateTime.now(),
          );
        }
      }

      // Finally, yield the last chunk with suggestions/resources
      final suggestions = <ChatSuggestion>[];
      final resources = <ChatResource>[];

      if (fullText.contains("plant") || fullText.contains("garden")) {
        suggestions.add(ChatSuggestion(text: "Show me more plants"));
        suggestions.add(ChatSuggestion(text: "Gardening tips"));
      }
      if (fullText.toLowerCase().contains("bee") ||
          fullText.toLowerCase().contains("pollinator")) {
        resources.add(
          ChatResource(
            title: "Bee-Friendly Gardening Guide",
            content: "Learn more about creating the perfect habitat...",
            linkUrl: "guide",
          ),
        );
      }

      yield ChatMessageModel(
        id: messageId,
        text: fullText,
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: suggestions,
        resources: resources,
      );
    } catch (e) {
      debugPrint('Error streaming message from Gemini: $e');
      yield ChatMessageModel(
        id: botMessageId ?? uuid.v4(),
        text: "I'm sorry, I encountered an error. Please try again.",
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }
  
  /// Get a structured JSON response from Gemini
  /// 
  /// This method uses a JSON schema to get a structured response from Gemini
  /// It returns the parsed JSON as a Map<String, dynamic>
  Future<Map<String, dynamic>> getStructuredResponse({
    required List<Content> content,
    required Schema schema,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    debugPrint('Getting structured response with JSON schema');
    
    try {
      // Create a new model instance with JSON response configuration
      final structuredModel = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-2.0-flash-lite',
        generationConfig: GenerationConfig(
          temperature: 0.2, // Lower temperature for more predictable structured output
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
          responseMimeType: 'application/json',
          responseSchema: schema,
        ),
      );
      
      // Update the first text content to specify we want ONE result
      if (content.isNotEmpty && content[0].parts.isNotEmpty) {
        for (int i = 0; i < content[0].parts.length; i++) {
          if (content[0].parts[i] is TextPart) {
            TextPart textPart = content[0].parts[i] as TextPart;
            String originalText = textPart.text;
            
            // Modify the prompt to emphasize we want one result
            String modifiedText = originalText + "\n\nIMPORTANT: Provide only ONE identification with the highest confidence. Do NOT return a list of multiple identifications.";
            
            // Replace the original TextPart with the modified one
            content[0].parts[i] = TextPart(modifiedText);
            break;
          }
        }
      }
      
      // Send the request with content
      final response = await structuredModel.generateContent(content);
      
      // Parse and return the response as JSON
      if (response.text != null) {
        // The response comes as a JSON string in the text property
        final jsonString = response.text!;
        debugPrint('Received structured response: $jsonString');
        
        // Try to parse the response - it might be a list or a single object
        dynamic parsedJson;
        
        try {
          // First, try to extract the JSON from functionResponse.outputs
          final jsonMap = jsonDecode(response.text!);
          parsedJson = jsonMap;
        } catch (e) {
          // If that fails, try to parse the text directly
          debugPrint('Failed to extract from functionResponse, parsing text directly');
          try {
            parsedJson = json.decode(jsonString);
          } catch (e) {
            debugPrint('Failed to parse response as JSON: $e');
            throw Exception('Invalid JSON response');
          }
        }
        
        // Check if the response is a list or a single object
        if (parsedJson is List) {
          debugPrint('Response is a list, taking the first item');
          // If it's a list, take the first item (highest confidence)
          if (parsedJson.isEmpty) {
            throw Exception('Empty identification list returned');
          }
          return Map<String, dynamic>.from(parsedJson[0]);
        } else if (parsedJson is Map) {
          // If it's already a map, return it
          return Map<String, dynamic>.from(parsedJson);
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Empty response received from Gemini');
      }
    } catch (e) {
      debugPrint('Error getting structured response: $e');
      // Return a basic error structure
      return {
        'error': true,
        'message': 'Failed to analyze: $e',
      };
    }
  }
}