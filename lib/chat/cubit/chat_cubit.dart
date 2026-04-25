import 'dart:async';

import 'package:fly_bloc/fly_bloc.dart';
import 'package:makerlog/bot/cubit/bot_cubit.dart';
import 'package:makerlog/bot/cubit/bot_state.dart';
import 'package:makerlog/chat/cubit/chat_state.dart';
import 'package:makerlog/chat/repository/chat_message.dart';
import 'package:makerlog/chat/repository/chat_repository.dart';
import 'package:makerlog/chat/repository/machine_prompt.dart';
import 'package:makerlog/ollama_setup/cubit/ollama_setup_cubit.dart';
import 'package:makerlog/ollama_setup/cubit/ollama_setup_state.dart';

/// Drives the chat flow: replays `setupPrompts()` one at a time,
/// "typing" each prompt with a 20-char/sec ticker, then waits for the
/// human to reply.
///
/// For the `chat_assistant_setup` prompt the cubit doesn't stop for
/// the human — it hands control to, in order, [OllamaSetupCubit]
/// (install the binary / start the daemon) and then [BotCubit] (pull
/// the model), mirroring each cubit's status messages into the chat
/// log as system lines so the user sees the machine narrate what
/// it's doing. Once the last subsystem reaches a terminal state the
/// chat advances on its own.
class ChatCubit extends Cubit<ChatState> {
  final ChatRepository repository;
  final OllamaSetupCubit ollamaSetupCubit;
  final BotCubit botCubit;

  Timer? _typingTimer;
  StreamSubscription<OllamaSetupState>? _setupSubscription;
  StreamSubscription<BotState>? _botSubscription;
  OllamaSetupStatus? _lastSetupStatus;
  BotStatus? _lastBotStatus;

  static const Duration _tickInterval = Duration(milliseconds: 50);

  ChatCubit({
    required this.repository,
    required this.ollamaSetupCubit,
    required this.botCubit,
  }) : super(const ChatState()) {
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
    if (prompt.key == ChatPromptKeys.chatAssistantSetup) {
      emit(state.copyWith(
        clearTypingRevealed: true,
        options: const [],
        awaitingUserInput: false,
      ));
      _runOllamaSetup();
      return;
    }

    emit(state.copyWith(
      clearTypingRevealed: true,
      options: prompt.options,
      awaitingUserInput: true,
    ));
  }

  void _runOllamaSetup() {
    _lastSetupStatus = null;
    _setupSubscription?.cancel();
    _setupSubscription =
        ollamaSetupCubit.stream.listen(_onOllamaSetupStateChanged);
    unawaited(ollamaSetupCubit.ensureRunning());
  }

  void _onOllamaSetupStateChanged(OllamaSetupState setupState) {
    // Append on every status change; for the chatty `installing`
    // stream, rewrite the tail in place so we don't flood the log.
    if (setupState.status != _lastSetupStatus) {
      _appendSystemMessage(setupState.message);
      _lastSetupStatus = setupState.status;
    } else if (setupState.status == OllamaSetupStatus.installing) {
      _replaceTailSystemMessage(setupState.message);
    }

    if (setupState.isReady) {
      _setupSubscription?.cancel();
      _setupSubscription = null;
      _runBotSetup();
    } else if (setupState.isTerminalFailure) {
      _setupSubscription?.cancel();
      _setupSubscription = null;
      _advancePastSetup();
    }
  }

  void _runBotSetup() {
    _lastBotStatus = null;
    _botSubscription?.cancel();
    _botSubscription = botCubit.stream.listen(_onBotStateChanged);
    unawaited(botCubit.ensureReady());
  }

  void _onBotStateChanged(BotState botState) {
    if (botState.status != _lastBotStatus) {
      _appendSystemMessage(botState.message);
      _lastBotStatus = botState.status;
    } else if (botState.status == BotStatus.installing) {
      _replaceTailSystemMessage(botState.message);
    }

    if (botState.isReady || botState.isTerminalFailure) {
      _botSubscription?.cancel();
      _botSubscription = null;
      _advancePastSetup();
    }
  }

  void _advancePastSetup() {
    emit(state.copyWith(
      currentPromptIndex: state.currentPromptIndex + 1,
    ));
    _presentNextPrompt();
  }

  void _appendSystemMessage(String text) {
    if (text.isEmpty) return;
    final message = ChatMessage(
      timestamp: DateTime.now(),
      text: text,
      sender: ChatSender.system,
    );
    repository.append(message);
    emit(state.copyWith(
      messages: [...state.messages, message],
    ));
  }

  void _replaceTailSystemMessage(String text) {
    if (text.isEmpty || state.messages.isEmpty) return;
    final tail = state.messages.last;
    if (tail.sender != ChatSender.system) {
      _appendSystemMessage(text);
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
      _runBotAnswer(trimmed);
    } else {
      _presentNextPrompt();
    }
  }

  void _runBotAnswer(String userQuestion) {
    // Seed an empty system message that the bot stream will fill in
    // as tokens arrive — `_replaceTailSystemMessage` updates it in
    // place so the UI shows a single growing reply bubble.
    _appendSystemMessage(' ');
    _lastBotStatus = null;
    _botSubscription?.cancel();
    _botSubscription = botCubit.stream.listen(_onBotAnswerStateChanged);
    unawaited(botCubit.askForThreeAnswers(userQuestion));
  }

  void _onBotAnswerStateChanged(BotState botState) {
    switch (botState.status) {
      case BotStatus.answering:
        if (botState.message.isNotEmpty) {
          _replaceTailSystemMessage(botState.message);
        }
      case BotStatus.answered:
        _replaceTailSystemMessage(botState.message);
        _botSubscription?.cancel();
        _botSubscription = null;
        _presentNextPrompt();
      case BotStatus.error:
        _replaceTailSystemMessage(botState.message);
        _botSubscription?.cancel();
        _botSubscription = null;
        _presentNextPrompt();
      default:
        break;
    }
  }

  @override
  Future<void> close() {
    _typingTimer?.cancel();
    _setupSubscription?.cancel();
    _botSubscription?.cancel();
    return super.close();
  }
}
