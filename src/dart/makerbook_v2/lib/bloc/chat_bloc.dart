import 'package:clitter/clitter.dart';

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

/// Holds the chat log. Expose a small command API ([send]) and keep
/// state derivation to pure functions inside [ChatState].
class ChatBloc extends Cubit<ChatState> {
  ChatBloc() : super(const ChatState());

  /// Append a user message. Blank submissions are ignored so hitting
  /// Enter in an empty field doesn't clutter the log.
  void send(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    emit(state.addMessage(trimmed));
  }
}
