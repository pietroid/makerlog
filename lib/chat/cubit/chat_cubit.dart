import 'dart:async';

import 'package:fly_bloc/fly_bloc.dart';
import 'package:makerlog/chat/cubit/chat_state.dart';
import 'package:makerlog/chat/repository/chat_message.dart';
import 'package:makerlog/chat/repository/chat_repository.dart';
import 'package:makerlog/chat/repository/machine_prompt.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository repository;

  Timer? _typingTimer;

  static const Duration _tickInterval = Duration(milliseconds: 50);

  ChatCubit({required this.repository}) : super(const ChatState()) {
    _presentNextPrompt();
  }

  void appendSystemMessage(String text) {
    if (text.isEmpty) return;
    final message = ChatMessage(
      timestamp: DateTime.now(),
      text: text,
      sender: ChatSender.system,
    );
    repository.append(message);
    emit(state.copyWith(messages: [...state.messages, message]));
  }

  void replaceTailSystemMessage(String text) {
    if (text.isEmpty || state.messages.isEmpty) return;
    final tail = state.messages.last;
    if (tail.sender != ChatSender.system) {
      appendSystemMessage(text);
      return;
    }
    final replaced = ChatMessage(
      timestamp: tail.timestamp,
      text: text,
      sender: ChatSender.system,
    );
    final next = [...state.messages];
    next[next.length - 1] = replaced;
    emit(state.copyWith(messages: next));
  }

  void advanceAfterSetup() {
    emit(state.copyWith(currentPromptIndex: state.currentPromptIndex + 1));
    _presentNextPrompt();
  }

  void advanceAfterBotAnswer() {
    _presentNextPrompt();
  }

  void _presentNextPrompt() {
    final prompts = repository.setupPrompts();
    if (state.currentPromptIndex >= prompts.length) {
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
        _onTypingFinished(prompt);
      } else {
        emit(state.copyWith(typingRevealed: next));
      }
    });
  }

  void _onTypingFinished(MachinePrompt prompt) {
    emit(state.copyWith(
      clearTypingRevealed: true,
      options: prompt.options,
      awaitingUserInput: true,
    ));
  }

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
    final prompts = repository.setupPrompts();
    final activePrompt = wasAwaiting && state.currentPromptIndex < prompts.length
        ? prompts[state.currentPromptIndex]
        : null;

    emit(state.copyWith(
      messages: [...state.messages, message],
      awaitingUserInput: false,
      options: const [],
      currentPromptIndex:
          wasAwaiting ? state.currentPromptIndex + 1 : state.currentPromptIndex,
    ));

    if (!wasAwaiting) return;
    if (activePrompt?.forwardToBot == true) {
      _presentNextPrompt();
    } else {
      _presentNextPrompt();
    }
  }

  @override
  Future<void> close() {
    _typingTimer?.cancel();
    return super.close();
  }
}
