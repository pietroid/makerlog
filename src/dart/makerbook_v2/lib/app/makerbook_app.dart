import 'package:clitter/clitter.dart';

import '../bloc/chat_bloc.dart';
import '../widgets/chat_history.dart';
import '../widgets/header.dart';
import '../widgets/input_bar.dart';

/// Root widget — lays out the three regions of the UI:
///
///   Header         (fixed height: 2 rows)
///   ChatHistory    (Expanded, fills the middle)
///   InputBar       (fixed height: 3 rows — divider + input + padding)
///
/// All persistent state lives on this instance. That's important:
/// `build()` runs every frame, and any widget created *inside* it is
/// discarded after layout — so anything that needs to survive across
/// rebuilds (BLoCs, text controllers) has to be a field here, not a
/// child's field.
class MakerbookApp extends StatelessWidget {
  final ChatBloc chatBloc = ChatBloc();

  /// Input state lives up here for the same reason as [chatBloc]:
  /// if it lived on [InputBar] each keystroke would be written to a
  /// freshly-built, about-to-be-thrown-away controller.
  final TextEditingController inputController = TextEditingController();

  MakerbookApp();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(),
        Expanded(
          child: ChatHistory(bloc: chatBloc),
        ),
        InputBar(bloc: chatBloc, controller: inputController),
      ],
    );
  }
}
