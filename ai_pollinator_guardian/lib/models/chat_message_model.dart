class ChatMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<ChatSuggestion> suggestions;
  final List<ChatResource> resources;

  ChatMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestions = const [],
    this.resources = const [],
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      suggestions: (json['suggestions'] as List?)
          ?.map((e) => ChatSuggestion.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      resources: (json['resources'] as List?)
          ?.map((e) => ChatResource.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'suggestions': suggestions.map((s) => s.toJson()).toList(),
      'resources': resources.map((r) => r.toJson()).toList(),
    };
  }
}

class ChatSuggestion {
  final String text;

  ChatSuggestion({required this.text});

  factory ChatSuggestion.fromJson(Map<String, dynamic> json) {
    return ChatSuggestion(
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
    };
  }
}

class ChatResource {
  final String title;
  final String content;
  final String? linkUrl;
  final String? imageUrl;

  ChatResource({
    required this.title,
    required this.content,
    this.linkUrl,
    this.imageUrl,
  });

  factory ChatResource.fromJson(Map<String, dynamic> json) {
    return ChatResource(
      title: json['title'] as String,
      content: json['content'] as String,
      linkUrl: json['linkUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'linkUrl': linkUrl,
      'imageUrl': imageUrl,
    };
  }
}