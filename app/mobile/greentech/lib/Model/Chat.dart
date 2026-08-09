class ChatReply {
  const ChatReply({
    required this.conversationId,
    required this.reply,
    required this.toolsUsed,
    required this.historyLength,
  });

  final String conversationId;
  final String reply;
  final List<String> toolsUsed;
  final int historyLength;

  factory ChatReply.fromJson(Map<String, dynamic> json) => ChatReply(
    conversationId: json['conversationId']?.toString() ?? '',
    reply: json['reply']?.toString() ?? '',
    toolsUsed:
        (json['toolsUsed'] as List?)?.map((tool) => tool.toString()).toList() ??
        const [],
    historyLength: (json['historyLength'] as num?)?.toInt() ?? 0,
  );
}

class ChatCapabilities {
  const ChatCapabilities({
    required this.enabled,
    required this.role,
    required this.suggestions,
  });

  final bool enabled;
  final String role;
  final List<String> suggestions;

  static const ChatCapabilities disabled = ChatCapabilities(
    enabled: false,
    role: '',
    suggestions: [],
  );

  factory ChatCapabilities.fromJson(Map<String, dynamic> json) =>
      ChatCapabilities(
        enabled: json['enabled'] == true,
        role: json['role']?.toString() ?? '',
        suggestions:
            (json['suggestions'] as List?)
                ?.map((item) => item.toString())
                .toList() ??
            const [],
      );
}

enum ChatAuthor { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.author,
    required this.content,
    required this.toolsUsed,
    required this.createdAt,
    this.pending = false,
    this.failed = false,
  });

  final ChatAuthor author;
  final String content;
  final List<String> toolsUsed;
  final DateTime? createdAt;
  final bool pending;
  final bool failed;

  bool get isUser => author == ChatAuthor.user;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    author: (json['author']?.toString().toUpperCase() ?? '') == 'USER'
        ? ChatAuthor.user
        : ChatAuthor.assistant,
    content: json['content']?.toString() ?? '',
    toolsUsed:
        (json['toolsUsed'] as List?)?.map((tool) => tool.toString()).toList() ??
        const [],
    createdAt: DateTime.tryParse(
      json['createdAt']?.toString() ?? '',
    )?.toLocal(),
  );
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.title,
    required this.messageCount,
    required this.lastMessageAt,
  });

  final String id;
  final String title;
  final int messageCount;
  final DateTime? lastMessageAt;

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        id: json['conversationId']?.toString() ?? json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Conversation',
        messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
        lastMessageAt: DateTime.tryParse(
          json['lastMessageAt']?.toString() ?? '',
        )?.toLocal(),
      );
}
