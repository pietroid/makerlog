import 'package:bloc/bloc.dart';
import 'package:clitter/clitter.dart';

/// Rebuilds a subtree from a [BlocBase]'s current state. Equivalent
/// in spirit to flutter_bloc's `BlocBuilder`: the [builder] runs every
/// frame and receives the latest state.
///
/// If [bloc] is omitted, the nearest ancestor [BlocProvider] of type
/// [B] is resolved via `context.read<B>()`.
///
/// No explicit subscription is needed — clitter installs a global
/// [BlocObserver] in `runApp` that calls `App.scheduleRebuild` on
/// every state change, so any emit anywhere triggers a repaint and
/// the next build sees `bloc.state`.
class BlocBuilder<B extends BlocBase<S>, S> extends StatelessWidget {
  final B? bloc;
  final Widget Function(BuildContext context, S state) builder;

  BlocBuilder({this.bloc, required this.builder});

  @override
  Widget build(BuildContext context) {
    final b = bloc ?? context.read<B>();
    return builder(context, b.state);
  }
}
