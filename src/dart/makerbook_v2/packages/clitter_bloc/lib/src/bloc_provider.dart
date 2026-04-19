import 'package:bloc/bloc.dart';
import 'package:clitter/clitter.dart';

/// Exposes a [BlocBase] instance to descendants via [BuildContext.read].
///
/// Mirrors the `flutter_bloc` API:
///
/// ```dart
/// BlocProvider<AppCubit>(
///   create: (context) => AppCubit(),
///   child: MyWidget(),
/// )
/// ```
///
/// Or, to expose an existing bloc without transferring ownership:
///
/// ```dart
/// BlocProvider<AppCubit>.value(value: appCubit, child: MyWidget())
/// ```
///
/// Implemented as a [StatefulWidget] so the bloc is constructed once
/// per mount — even though `build()` recreates the BlocProvider widget
/// every frame, its [State] (and the bloc it owns) survives via
/// [Framework]'s path-keyed state cache. The `create`-constructed
/// bloc is `close()`d automatically when the widget leaves the tree.
class BlocProvider<T extends BlocBase<Object?>>
    extends SingleChildStatefulWidget {
  final T Function(BuildContext context)? _create;
  final T? _value;

  BlocProvider({
    required T Function(BuildContext context) create,
    super.child,
    super.key,
  })  : _create = create,
        _value = null;

  BlocProvider.value({
    required T value,
    super.child,
    super.key,
  })  : _create = null,
        _value = value;

  @override
  State<BlocProvider<T>> createState() => _BlocProviderState<T>();
}

class _BlocProviderState<T extends BlocBase<Object?>>
    extends State<BlocProvider<T>> {
  late T _bloc;
  bool _ownsBloc = false;

  @override
  void initState() {
    super.initState();
    final value = widget._value;
    if (value != null) {
      _bloc = value;
    } else {
      _bloc = widget._create!(context);
      _ownsBloc = true;
    }
  }

  @override
  void dispose() {
    if (_ownsBloc) _bloc.close();
    super.dispose();
  }

  @override
  BuildContext buildContext(BuildContext parent) => parent.provide<T>(_bloc);

  @override
  Widget build(BuildContext context) {
    assert(widget.child != null, 'BlocProvider was built without a child');
    return widget.child!;
  }
}
