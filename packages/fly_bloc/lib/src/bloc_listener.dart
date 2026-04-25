import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fly/fly.dart';

class BlocListener<B extends BlocBase<S>, S> extends StatefulWidget {
  final B? bloc;
  final Widget child;
  final bool Function(S previous, S current)? listenWhen;
  final void Function(BuildContext context, S state)? listener;

  BlocListener({
    this.bloc,
    required this.child,
    this.listenWhen,
    this.listener,
    super.key,
  });

  @override
  State<BlocListener<B, S>> createState() => _BlocListenerState<B, S>();
}

class _BlocListenerState<B extends BlocBase<S>, S>
    extends State<BlocListener<B, S>> {
  late B _bloc;
  late S _previousState;
  StreamSubscription<S>? _sub;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<B>();
    _previousState = _bloc.state;
    _sub = _bloc.stream.listen((current) {
      final previous = _previousState;
      if (widget.listenWhen == null || widget.listenWhen!(previous, current)) {
        widget.listener?.call(context, current);
      }
      setState(() => _previousState = current);
    });
  }

  @override
  void didUpdateWidget(BlocListener<B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.bloc ?? context.read<B>();
    if (!identical(next, _bloc)) {
      _sub?.cancel();
      _bloc = next;
      _previousState = _bloc.state;
      _sub = _bloc.stream.listen((current) {
        final previous = _previousState;
        if (widget.listenWhen == null ||
            widget.listenWhen!(previous, current)) {
          widget.listener?.call(context, current);
        }
        setState(() => _previousState = current);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}