import 'package:makerlog/chat/repository/chat_message.dart';
import 'package:makerlog/chat/repository/machine_prompt.dart';

/// Marker keys for prompts that are handled by non-chat machinery
/// (e.g. the bot setup flow) rather than waiting on the human.
class ChatPromptKeys {
  static const String chatAssistantSetup = 'chat_assistant_setup';
}

class ChatRepository {
  final List<ChatMessage> _history = [];

  List<ChatMessage> get history => List.unmodifiable(_history);

  void append(ChatMessage message) => _history.add(message);

  /// Prompts used for the first time user setups makerlog.
  List<MachinePrompt> setupPrompts() {
    return [
      MachinePrompt(
        key: 'welcome',
        prompt:
            'Hello, dear human. Welcome to makerlog. I am a humble program, designed to assist you in your creative endeavors. How would you like to call me when needed?',
        options: ['makerlog', 'thoth', 'ada', 'jarvis', 'hal'],
        freeFormHint: 'I want to call you...',
      ),
      MachinePrompt(
        key: 'setup_question',
        prompt:
            "Let's get it started! Makerlog is composed of (1) a simple interactive chat assistant (2) a worklog feed (3) a simple text editor (4) a living publish draft. I will walk you through each one of these, ok?",
        options: [
          'Lesgoo!',
          'I just want to start writing',
        ],
        freeFormHint: '',
      ),
      MachinePrompt(
        key: ChatPromptKeys.chatAssistantSetup,
        prompt:
            "Let's enable all my powers. I will need to check if I have any local models available...",
        options: [],
      ),
      MachinePrompt(
        key: 'bot_hello',
        prompt:
            "Ask me what's the answer to life, the universe and everything.",
        options: [],
        freeFormHint: 'Ask away...',
        forwardToBot: true,
      ),
    ];
  }
}
