import 'package:fly/fly.dart';

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

  final String? placeholder;

  InputBar({
    required this.bloc,
    required this.controller,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.black,
      height: 1,
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Row(
        children: [
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
              placeholder: placeholder ?? 'type here...',
              onSubmit: (text) {
                bloc.submit(text);
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
