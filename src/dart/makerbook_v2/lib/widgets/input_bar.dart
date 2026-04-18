import 'package:clitter/clitter.dart';

import '../chat/cubit/chat_cubit.dart';

/// Bottom input bar: a dark, single-row strip with a prompt marker and
/// the TextField. Hits Enter to submit into the chat BLoC and clear.
class InputBar extends StatelessWidget {
  final ChatCubit bloc;

  /// Injected by the parent. Must outlive a single rebuild — see
  /// [MakerbookApp]'s note. A TextField without a stable controller
  /// swallows keystrokes because each frame it reads a fresh, empty
  /// instance.
  final TextEditingController controller;

  InputBar({required this.bloc, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Dark background so the input visually "sits below" the chat
      // content. Extends edge-to-edge because Container paints a fill.
      color: Color.black,
      height: 1,
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Row(
        children: [
          // Prompt marker in bright cyan — no background set, so the
          // Container's black shows through (that's the merge rule).
          Text(
            '❯ ',
            style: const TextStyle(
              color: Color.brightCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              placeholder: 'type here...',
              onSubmit: (text) {
                bloc.send(text);
                controller.clear();
              },
              style: const TextStyle(color: Color.brightWhite),
              placeholderStyle: const TextStyle(
                color: Color.brightBlack,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
