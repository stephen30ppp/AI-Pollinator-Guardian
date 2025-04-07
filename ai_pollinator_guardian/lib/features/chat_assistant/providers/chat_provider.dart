import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/models/chat_message_model.dart';
import 'package:ai_pollinator_guardian/services/gemini_service.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final List<ChatMessageModel> _messages = [];
  bool _isTyping = false;
  bool _isInitialized = false;
  StreamSubscription? _messageStreamSubscription;
  final uuid = Uuid();

  List<ChatMessageModel> get messages => _messages;
  bool get isTyping => _isTyping;
  
  // Initialize the chat
  Future<void> initialize() async {
    if (!_isInitialized) {
      await _geminiService.initialize();
      final welcomeMessage = await _geminiService.startNewChat();
      _messages.add(welcomeMessage);
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  // Send a text message from the user
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    // Add user message
    final userMessage = ChatMessageModel(
      id: uuid.v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();
    
    // Show typing indicator
    _isTyping = true;
    notifyListeners();
    
    // Use streaming for better UX
    _messageStreamSubscription?.cancel();
    
    // Create a temporary bot message ID to track updates
    final String tempBotMessageId = uuid.v4();
    
    // Add an initial empty bot message (will be updated by the stream)
    final initialBotMessage = ChatMessageModel(
      id: tempBotMessageId,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(initialBotMessage);
    notifyListeners();
    
    final messageStream = _geminiService.sendMessageStream(
      text,
      botMessageId: tempBotMessageId
    );
    _messageStreamSubscription = messageStream.listen(
      (updatedMessage) {
        // Find and update the temporary message
        final index = _messages.indexWhere((m) => m.id == tempBotMessageId);
        if (index != -1) {
          _messages[index] = updatedMessage;
          _isTyping = false;
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('Error in message stream: $error');
        _isTyping = false;
        notifyListeners();
      },
      onDone: () {
        _isTyping = false;
        notifyListeners();
      },
    );
  }
  
  // Handle suggestion chip taps
  void sendSuggestion(String suggestion) {
    sendMessage(suggestion);
  }
  
  // Start a new chat
  Future<void> startNewChat() async {
    _messages.clear();
    final welcomeMessage = await _geminiService.startNewChat();
    _messages.add(welcomeMessage);
    notifyListeners();
  }
  
  @override
  void dispose() {
    _messageStreamSubscription?.cancel();
    super.dispose();
  }
}