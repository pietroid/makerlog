import 'dart:async';

import 'package:fly_bloc/fly_bloc.dart';
import 'package:makerlog/chat/cubit/chat_state.dart';
import 'package:makerlog/chat/repository/chat_message.dart';
import 'package:makerlog/chat/repository/chat_repository.dart';

/// Drives the chat flow: replays `initialPrompts()` one at a time,
/// "typing" each prompt with a 5-char/sec ticker, then waits for the
/// human to reply (either by selecting a canned option or typing free
/// form). Every message is appended to [ChatRepository]'s in-memory
/// log.
class ChatCubit extends Cubit<ChatState> {
  final ChatRepository repository;
  Timer? _typingTimer;

  static const Duration _tickInterval = Duration(milliseconds: 50);

  ChatCubit({required this.repository}) : super(const ChatState()) {
    _presentNextPrompt();
  }

  void _presentNextPrompt() {
    final prompts = repository.initialPrompts();
    if (state.currentPromptIndex >= prompts.length) {
      // Out of scripted prompts — just let the human keep typing.
      emit(state.copyWith(
        awaitingUserInput: true,
        options: const [],
        clearTypingRevealed: true,
      ));
      return;
    }

    final prompt = prompts[state.currentPromptIndex];
    final message = ChatMessage(
      timestamp: DateTime.now(),
      text: prompt.prompt,
      sender: ChatSender.system,
    );
    repository.append(message);

    emit(state.copyWith(
      messages: [...state.messages, message],
      typingRevealed: 0,
      options: const [],
      awaitingUserInput: false,
    ));

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(_tickInterval, (timer) {
      final revealed = state.typingRevealed ?? 0;
      final next = revealed + 1;
      if (next >= message.text.length) {
        timer.cancel();
        _typingTimer = null;
        emit(state.copyWith(
          clearTypingRevealed: true,
          options: prompt.options,
          awaitingUserInput: true,
        ));
      } else {
        emit(state.copyWith(typingRevealed: next));
      }
    });
  }

  /// Submit a free-form message from the human. Also used internally
  /// when an option is picked — the option's text is sent as if typed.
  void submit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final message = ChatMessage(
      timestamp: DateTime.now(),
      text: trimmed,
      sender: ChatSender.human,
    );
    repository.append(message);

    final wasAwaiting = state.awaitingUserInput;
    emit(state.copyWith(
      messages: [...state.messages, message],
      awaitingUserInput: false,
      options: const [],
      currentPromptIndex:
          wasAwaiting ? state.currentPromptIndex + 1 : state.currentPromptIndex,
    ));

    if (wasAwaiting) _presentNextPrompt();
  }

  @override
  Future<void> close() {
    _typingTimer?.cancel();
    return super.close();
  }
}
