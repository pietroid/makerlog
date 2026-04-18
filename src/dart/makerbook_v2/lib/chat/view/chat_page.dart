import 'package:clitter/clitter.dart';
import 'package:makerbook_v2/chat/widgets/chat_history.dart';

class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // // Left panel: list of conversations (not implemented yet)
        // Container(
        //   width: 200,
        //   color: Colors.grey[200],
        //   child: const Center(child: Text('Conversations')),
        // ),

        // // Middle panel: scrollable-looking list of past messages. Subscribed
        // // to [ChatBloc] via [BlocBuilder] so any new message triggers a
        // // rebuild.
        // const Expanded(child: ChatHistory()),

        // // Right panel: input box for sending new messages. Also subscribed
        // // to [ChatBloc] so it can clear itself after sending a message.
        // const SizedBox(width: 300, child: ChatInput()),
      ],
    );
  }
}
