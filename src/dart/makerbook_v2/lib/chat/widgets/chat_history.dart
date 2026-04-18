import 'package:clitter/clitter.dart';
import 'package:clitter_bloc/clitter_bloc.dart';
import 'package:makerbook_v2/chat/cubit/chat_state.dart';

import '../cubit/chat_cubit.dart';

/// Middle panel: scrollable-looking list of past messages. Subscribed
/// to [ChatBloc] via [BlocBuilder] so any new message triggers a
/// rebuild automatically.
///
/// "Scrolling" here is fake — we just show the most recent N messages
/// that fit. That's fine for a small chat log and keeps layout simple.
class ChatHistory extends StatelessWidget {
  final ChatCubit bloc;

  ChatHistory({required this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      bloc: bloc,
      builder: (context, state) {
        // Show a dim empty-state hint when nothing has been typed yet.
        if (state.messages.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(1),
            child: Text(
              '(no messages yet — start typing below)',
              style: const TextStyle(
                color: Color.brightBlack,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        // Render one Text per message, newest at the bottom. The
        // surrounding Expanded in MakerbookApp bounds the height, so
        // rows that overflow are clipped by the Canvas.
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          child: Column(
            children: [
              for (final msg in state.messages)
                Text(
                  '❯ $msg',
                  style: const TextStyle(color: Color.brightGreen),
                ),
            ],
          ),
        );
      },
    );
  }
}
