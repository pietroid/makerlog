import 'package:clitter_bloc/clitter_bloc.dart';
import 'package:makerbook_v2/chat/cubit/chat_state.dart';

/// Holds the chat log. Expose a small command API ([send]) and keep
/// state derivation to pure functions inside [ChatState].
class ChatCubit extends Cubit<ChatState> {
  ChatCubit() : super(const ChatState());

  /// Append a user message. Blank submissions are ignored so hitting
  /// Enter in an empty field doesn't clutter the log.
  void send(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    emit(state.addMessage(trimmed));
  }
}
