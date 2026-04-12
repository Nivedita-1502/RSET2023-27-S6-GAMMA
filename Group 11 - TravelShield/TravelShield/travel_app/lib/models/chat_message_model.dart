// lib/models/chat_message_model.dart

enum MessageSender { user, bot }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isError = false,
  });

  bool get isUser => sender == MessageSender.user;
  bool get isBot => sender == MessageSender.bot;

  ChatMessage copyWith({
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isError,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
    );
  }
}