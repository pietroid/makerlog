import 'package:makerbook_v2/chat/repository/chat_message.dart';
import 'package:makerbook_v2/chat/repository/machine_prompt.dart';

class ChatRepository {
  final List<ChatMessage> _history = [];

  List<ChatMessage> get history => List.unmodifiable(_history);

  void append(ChatMessage message) => _history.add(message);

  List<MachinePrompt> initialPrompts() {
    return [
      MachinePrompt(
        key: "welcome",
        prompt:
            "Hello, dear human. Welcome to makerlog. We are here to help you to make great stuff and to share it with the world. First, how do you want to call your assistant? You will use to call me with an @ anytime, so choose wisely.",
        options: [
          "Ada",
          "Hal",
          "Jarvis",
        ],
        freeFormHint: "I want to call you...",
      ),
      MachinePrompt(
        key: "what_to_do",
        prompt: "What do you want to do today?",
        options: [
          "I want to create a new project",
          "I don't know, I want to learn something new today",
        ],
        freeFormHint: "I want to...",
      ),
    ];
  }
}
