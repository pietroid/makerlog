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
/// The [create] callback runs lazily on first access and the bloc is
/// cached so the widget's per-frame rebuild doesn't spin up new blocs.
///
/// Inside the subtree:
///
/// ```dart
/// final cubit = context.read<AppCubit>();
/// BlocBuilder<AppCubit, AppState>(builder: (c, s) => ...);
/// ```
class BlocProvider<T extends BlocBase<Object?>>
    extends SingleChildStatelessWidget {
  final T Function(BuildContext context)? _create;
  final T? _value;
  T? _instance;

  BlocProvider({
    required T Function(BuildContext context) create,
    super.child,
  })  : _create = create,
        _value = null;

  BlocProvider.value({required T value, super.child})
      : _create = null,
        _value = value,
        _instance = value;

  T _resolve(BuildContext context) {
    if (_value != null) return _value!;
    return _instance ??= _create!(context);
  }

  @override
  BuildContext buildContext(BuildContext parent) =>
      parent.provide<T>(_resolve(parent));
}
