import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fly/fly.dart';

/// Rebuilds a subtree from a [BlocBase]'s current state. Equivalent
/// in spirit to flutter_bloc's `BlocBuilder`: subscribes to the bloc
/// in [State.initState] and calls [State.setState] on each emit, so
/// only this subtree's rebuild is triggered (rather than the whole
/// app).
///
/// If [bloc] is omitted, the nearest ancestor [BlocProvider] of type
/// [B] is resolved via `context.read<B>()`.
class BlocBuilder<B extends BlocBase<S>, S> extends StatefulWidget {
  final B? bloc;
  final Widget Function(BuildContext context, S state) builder;

  BlocBuilder({this.bloc, required this.builder, super.key});

  @override
  State<BlocBuilder<B, S>> createState() => _BlocBuilderState<B, S>();
}

class _BlocBuilderState<B extends BlocBase<S>, S>
    extends State<BlocBuilder<B, S>> {
  late B _bloc;
  late S _state;
  StreamSubscription<S>? _sub;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<B>();
    _state = _bloc.state;
    _sub = _bloc.stream.listen((next) {
      setState(() => _state = next);
    });
  }

  @override
  void didUpdateWidget(BlocBuilder<B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the caller rewired this BlocBuilder to a different bloc
    // instance, swap the subscription. Most callers don't — they let
    // [bloc] resolve through context.read — but mirror flutter_bloc.
    final next = widget.bloc ?? context.read<B>();
    if (identical(next, _bloc)) return;
    _sub?.cancel();
    _bloc = next;
    _state = _bloc.state;
    _sub = _bloc.stream.listen((s) {
      setState(() => _state = s);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _state);
}
