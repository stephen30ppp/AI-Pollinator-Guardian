import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/models/chat_message_model.dart';
import 'package:ai_pollinator_guardian/services/gemini_service.dart';
import 'package:uuid/uuid.dart';

// 定义聊天上下文类型
enum ChatContextType { identify, garden }

class ChatProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final List<ChatMessageModel> _messages = [];
  ChatContextType? _ctx; // 当前上下文类型
  bool _isTyping = false;
  bool _isInitialized = false;
  StreamSubscription? _messageStreamSubscription;
  final uuid = Uuid();
  int _sessionId = 0; // 添加会话ID追踪

  List<ChatMessageModel> get messages => _messages;
  bool get isTyping => _isTyping;
  int get sessionId => _sessionId; // 提供会话ID的getter
  
  // 清空聊天历史和上下文
  void clear() {
    _messages.clear();
    _ctx = null;
    notifyListeners();
  }
  
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
    _sessionId++; // 增加会话ID
    final welcomeMessage = await _geminiService.startNewChat();
    _messages.add(welcomeMessage);
    notifyListeners();
  }
  
  // 添加系统消息
  void addSystemMessage(String text) {
    final systemMessage = ChatMessageModel(
      id: uuid.v4(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(systemMessage);
    notifyListeners();
  }
  
  // 添加系统图片消息（需要在GeminiService中实现相应功能）
  Future<void> addSystemImage(String imagePath) async {
    try {
      final imageMessage = await _geminiService.analyzeImage(imagePath);
      _messages.add(imageMessage);
      notifyListeners();
    } catch (e) {
      debugPrint('Error analyzing image: $e');
    }
  }
  
  // 根据上下文类型设置种子消息
  Future<void> seedFromContext(ChatContextType type, {String? label, String? imagePath}) async {
    // 确保聊天已初始化
    if (!_isInitialized) {
      await initialize();
    }
    
    clear();  // ① 先清空历史
    _ctx = type;
    
    // 如果提供了图片路径，先发送图片
    if (imagePath != null) {
      await addSystemImage(imagePath);
    }
    
    // 根据上下文类型发送相应的系统消息
    switch (type) {
      case ChatContextType.identify:
        addSystemMessage('You just identified "${label ?? 'a pollinator'}". Ask anything about it!');
        break;
      case ChatContextType.garden:
        addSystemMessage('Garden analysis complete. Need improvement tips?');
        break;
    }
  }
  
  @override
  void dispose() {
    _messageStreamSubscription?.cancel();
    super.dispose();
  }
}