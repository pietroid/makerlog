import 'dart:async';

import '../app.dart';

/// Minimal BLoC: holds a single state value [S] and broadcasts
/// changes on a stream. Any `emit` schedules a UI rebuild via
/// [App.scheduleRebuild] — the app doesn't have to subscribe
/// explicitly, the next paint picks up `state`.
///
/// Use it like flutter_bloc's `Cubit`:
///
/// ```dart
/// class CounterBloc extends Bloc<int> {
///   CounterBloc() : super(0);
///   void increment() => emit(state + 1);
/// }
/// ```
abstract class Bloc<S> {
  S _state;
  final StreamController<S> _controller = StreamController<S>.broadcast();

  Bloc(S initial) : _state = initial;

  /// Current state. Read this from `BlocBuilder.builder`.
  S get state => _state;

  /// Broadcast changes for callers that need to react to every emit
  /// (e.g. side effects). Not needed just to rebuild UI.
  Stream<S> get stream => _controller.stream;

  /// Push a new state. No-op if the state is the same as the current
  /// one (reference equality; override if you want deep-equal checks).
  void emit(S next) {
    if (identical(_state, next)) return;
    _state = next;
    _controller.add(next);
    App.scheduleRebuild();
  }

  /// Release the stream. Call when the bloc is no longer needed.
  Future<void> close() => _controller.close();
}
