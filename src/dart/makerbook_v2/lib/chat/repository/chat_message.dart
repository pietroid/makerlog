enum ChatSender { system, human }

class ChatMessage {
  final DateTime timestamp;
  final String text;
  final ChatSender sender;

  ChatMessage({
    required this.timestamp,
    required this.text,
    required this.sender,
  });
}
