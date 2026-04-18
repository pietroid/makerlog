/// Immutable snapshot of the chat. A new instance is emitted whenever
/// a message arrives.
class ChatState {
  final List<String> messages;

  const ChatState({this.messages = const []});

  /// Returns a copy with [message] appended.
  ChatState addMessage(String message) => ChatState(
        messages: [...messages, message],
      );
}
