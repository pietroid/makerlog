import 'package:app_ui/app_ui.dart';
import 'package:clitter/clitter.dart';
import 'package:clitter_bloc/clitter_bloc.dart';
import 'package:makerlog/chat/cubit/chat_cubit.dart';
import 'package:makerlog/chat/cubit/chat_state.dart';
import 'package:makerlog/chat/repository/chat_message.dart';

/// The scrolling chat log. Each row is `[hh:mm]  message` — a timestamp
/// column rendered in gray, a small gap, then the message body coloured
/// by sender. The last system message is subject to the typing ticker:
/// only [ChatState.typingRevealed] characters are shown until the
/// reveal completes.
class ChatConversation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        final rows = <Widget>[];
        for (int i = 0; i < state.messages.length; i++) {
          final message = state.messages[i];
          final isLast = i == state.messages.length - 1;
          final isTyping = isLast &&
              message.sender == ChatSender.system &&
              state.isSystemTyping;
          final text = isTyping
              ? message.text.substring(0, state.typingRevealed ?? 0)
              : message.text;
          rows.add(_MessageRow(
            timestamp: message.timestamp,
            text: text,
            sender: message.sender,
          ));
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          child: ListView(children: rows),
        );
      },
    );
  }
}

class _MessageRow extends StatelessWidget {
  final DateTime timestamp;
  final String text;
  final ChatSender sender;

  _MessageRow({
    required this.timestamp,
    required this.text,
    required this.sender,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (sender) {
      ChatSender.system => Color.rgb(0, 200, 150),
      ChatSender.human => Color.brightWhite,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatTime(timestamp),
          style: const TextStyle(color: Color.brightBlack),
        ),
        SizedBox.horizontal(2),
        Expanded(child: Text(text, style: TextStyle(color: color))),
      ],
    );
  }

  static String _formatTime(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
