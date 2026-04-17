import '../build_context.dart';
import '../widget.dart';
import 'bloc.dart';

/// Rebuilds a subtree from a [Bloc]'s current state. Equivalent in
/// spirit to flutter_bloc's `BlocBuilder`: the [builder] runs every
/// frame and receives the latest state.
///
/// No explicit subscription is needed — the bloc calls
/// [App.scheduleRebuild] on emit, which triggers the whole tree to
/// repaint. This `BlocBuilder` is mostly sugar for readability:
///
/// ```dart
/// BlocBuilder<ChatBloc, ChatState>(
///   bloc: chatBloc,
///   builder: (context, state) => Text('${state.messages.length} msgs'),
/// )
/// ```
class BlocBuilder<B extends Bloc<S>, S> extends StatelessWidget {
  final B bloc;
  final Widget Function(BuildContext context, S state) builder;

  BlocBuilder({required this.bloc, required this.builder});

  @override
  Widget build(BuildContext context) => builder(context, bloc.state);
}
