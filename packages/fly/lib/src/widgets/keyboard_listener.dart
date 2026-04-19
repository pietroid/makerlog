import '../build_context.dart';
import '../input.dart';
import '../widget.dart';

/// Flutter-style keyboard listener. Wrap any subtree to receive every
/// decoded [KeyEvent] while that subtree is mounted.
///
/// Unlike Flutter's version fly has no focus tree, so there is no
/// [FocusNode] to pass — a listener is always "active" while it's
/// painted. If multiple [KeyboardListener]s are in the tree they all
/// fire, in paint order.
///
/// Example:
/// ```dart
/// KeyboardListener(
///   onKeyEvent: (event) {
///     if (event.type != KeyType.other) navigator.push(NextPage());
///   },
///   child: OnboardingPage(),
/// )
/// ```
class KeyboardListener extends StatelessWidget {
  final void Function(KeyEvent event) onKeyEvent;
  final Widget child;

  KeyboardListener({required this.onKeyEvent, required this.child});

  @override
  Widget build(BuildContext context) {
    FocusManager.addKeyListener(onKeyEvent);
    return child;
  }
}
