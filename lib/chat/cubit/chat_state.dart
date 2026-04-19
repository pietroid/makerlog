import 'package:makerlog/chat/repository/chat_message.dart';

/// Immutable snapshot of the chat.
///
/// * [messages] — the full conversation log, oldest first.
/// * [typingRevealed] — when non-null, the trailing system message is
///   still being "typed" by the machine; this is the number of
///   characters currently visible. `null` means no typing in flight.
/// * [currentPromptIndex] — which prompt from
///   `ChatRepository.initialPrompts()` is active. Advances after the
///   human replies.
/// * [options] — pre-canned answers for the active prompt; empty when
///   none are offered (or while typing).
/// * [awaitingUserInput] — true once the machine has finished typing
///   and the human can reply.
class ChatState {
  final List<ChatMessage> messages;
  final int? typingRevealed;
  final int currentPromptIndex;
  final List<String> options;
  final bool awaitingUserInput;

  const ChatState({
    this.messages = const [],
    this.typingRevealed,
    this.currentPromptIndex = 0,
    this.options = const [],
    this.awaitingUserInput = false,
  });

  bool get isSystemTyping => typingRevealed != null;

  ChatState copyWith({
    List<ChatMessage>? messages,
    int? typingRevealed,
    bool clearTypingRevealed = false,
    int? currentPromptIndex,
    List<String>? options,
    bool? awaitingUserInput,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      typingRevealed:
          clearTypingRevealed ? null : (typingRevealed ?? this.typingRevealed),
      currentPromptIndex: currentPromptIndex ?? this.currentPromptIndex,
      options: options ?? this.options,
      awaitingUserInput: awaitingUserInput ?? this.awaitingUserInput,
    );
  }
}
