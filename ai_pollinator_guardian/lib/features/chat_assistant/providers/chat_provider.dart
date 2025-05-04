import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/models/chat_message_model.dart';
import 'package:ai_pollinator_guardian/services/gemini_service.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

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
  final List<Content> _history = []; // 添加历史栈

  List<ChatMessageModel> get messages => _messages;
  bool get isTyping => _isTyping;
  int get sessionId => _sessionId; // 提供会话ID的getter
  
  // 清空聊天历史和上下文
  void clear() {
    _messages.clear();
    _history.clear();  // 同时清空历史栈
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
    
    // Add user message to UI messages
    final userMessage = ChatMessageModel(
      id: uuid.v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    
    // 添加用户消息到历史栈 - 移除不支持的 role 参数
    _history.add(Content.text(text));
    
    notifyListeners();
    
    // Show typing indicator
    _isTyping = true;
    notifyListeners();
    
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
    
    try {
      // 使用完整历史栈调用sendMessageStream，确保不会丢失图片等上下文
      final messageStream = await _geminiService.sendMessageStreamWithHistory(
        _history,
        botMessageId: tempBotMessageId
      );
      
      String assistantResponse = '';
      
      _messageStreamSubscription = messageStream.listen(
        (updatedMessage) {
          // 更新 UI 消息
          final index = _messages.indexWhere((m) => m.id == tempBotMessageId);
          if (index != -1) {
            _messages[index] = updatedMessage;
            assistantResponse = updatedMessage.text;
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('Error in message stream: $error');
          _isTyping = false;
          notifyListeners();
        },
        onDone: () {
          // 当流完成时，将助手回复添加到历史栈 - 移除不支持的 role 参数
          if (assistantResponse.isNotEmpty) {
            _history.add(Content.text(assistantResponse));
          }
          _isTyping = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error sending message with history: $e');
      _isTyping = false;
      notifyListeners();
    }
  }
  
  // Handle suggestion chip taps
  void sendSuggestion(String suggestion) {
    sendMessage(suggestion);
  }
  
  // Start a new chat
  Future<void> startNewChat() async {
    _messages.clear();
    
    // 保留原始 history 中的图片内容（如果有）
    List<Content> imageContents = _history.where((content) => 
      content.parts.any((part) => part is InlineDataPart)
    ).toList();
    
    // 清空历史栈，但保留系统指令
    _history.clear();
    
    // 添加系统指令 - 移除不支持的 role 参数
    const systemInstructionText =
        "You are a helpful pollinator gardening assistant called 'Bee Guide'. "
        "Your primary goal is to help users protect and support pollinators. "
        "You can help with identifying pollinators, suggesting plants that attract specific pollinators, "
        "providing gardening tips, explaining pollinator behavior, and answering questions about "
        "conservation. Keep your responses friendly, concise, and focused on helping users create "
        "pollinator-friendly environments. Include specific, actionable advice when possible. "
        "For plant recommendations, focus on native plants when appropriate, and explain why they're beneficial.";
    
    _history.add(Content.text(systemInstructionText));
    
    // 将图片内容添加回历史（如果有）
    _history.addAll(imageContents);
    
    _sessionId++; // 增加会话ID
    
    // 使用保留了图片内容的历史创建新会话
    final welcomeMessage = await _geminiService.startNewChat(_history);
    _messages.add(welcomeMessage);
    
    // 将 assistant 的欢迎消息添加到历史栈 - 移除不支持的 role 参数
    _history.add(Content.text(welcomeMessage.text));
    
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
    
    // 将系统消息添加到历史栈中 - 移除不支持的 role 参数
    _history.add(Content.text(text));
    
    notifyListeners();
  }
  
  // 添加系统图片消息
  Future<void> addSystemImage(String imagePath) async {
    try {
      // 读取图片字节
      final Uint8List bytes = await File(imagePath).readAsBytes();
      
      // 添加图片到历史栈，使用 Content.multi 将图片和提示文本组合在一起
      final imagePart = InlineDataPart('image/jpeg', bytes);
      final promptPart = TextPart("Please analyze this image and remember it for our conversation.");
      
      // 将图片内容添加到历史栈中 - 移除不支持的 role 参数
      _history.add(Content.multi([imagePart, promptPart]));
      
      // 获取图片分析结果
      final imageMessage = await _geminiService.analyzeImage(imagePath);
      _messages.add(imageMessage);
      
      // 将AI的分析结果也添加到历史栈中 - 移除不支持的 role 参数
      _history.add(Content.text(imageMessage.text));
      
      notifyListeners();
      
      debugPrint('Image added to history stack with size: ${bytes.length} bytes');
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