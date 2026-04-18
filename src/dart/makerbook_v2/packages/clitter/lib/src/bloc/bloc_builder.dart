import 'package:bloc/bloc.dart';

import '../build_context.dart';
import '../widget.dart';

/// Rebuilds a subtree from a [BlocBase]'s current state. Equivalent
/// in spirit to flutter_bloc's `BlocBuilder`: the [builder] runs every
/// frame and receives the latest state.
///
/// No explicit subscription is needed — clitter installs a global
/// [BlocObserver] in `runApp` that calls `App.scheduleRebuild` on
/// every state change, so any emit anywhere triggers a repaint and
/// the next build sees `bloc.state`.
///
/// ```dart
/// BlocBuilder<ChatBloc, ChatState>(
///   bloc: chatBloc,
///   builder: (context, state) => Text('${state.messages.length} msgs'),
/// )
/// ```
class BlocBuilder<B extends BlocBase<S>, S> extends StatelessWidget {
  final B bloc;
  final Widget Function(BuildContext context, S state) builder;

  BlocBuilder({required this.bloc, required this.builder});

  @override
  Widget build(BuildContext context) => builder(context, bloc.state);
}
