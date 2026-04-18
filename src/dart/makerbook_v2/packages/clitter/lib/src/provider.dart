import 'build_context.dart';
import 'widget.dart';

/// Base for widgets that contribute a value to [BuildContext] for their
/// single [child] subtree. Having the child be mutable (instead of
/// required up front) lets [MultiProvider] re-link providers into a
/// nested chain at build time.
abstract class SingleChildStatelessWidget extends StatelessWidget {
  Widget? child;
  SingleChildStatelessWidget({this.child});

  @override
  Widget build(BuildContext context) {
    assert(child != null, '$runtimeType was built without a child');
    return child!;
  }
}

/// Exposes a plain value (service, repository, config — anything
/// non-bloc) to descendants via [BuildContext.read].
///
/// Mirrors the `package:provider` API:
///
/// ```dart
/// Provider<AuthService>(
///   create: (context) => AuthService(),
///   child: MyWidget(),
/// )
/// ```
///
/// Or, to expose a pre-built instance, use [Provider.value]:
///
/// ```dart
/// Provider<AuthService>.value(value: existing, child: MyWidget())
/// ```
///
/// The [create] callback runs lazily the first time the value is
/// resolved and the result is cached on the widget — so rebuilds
/// don't allocate a new instance every frame.
class Provider<T extends Object> extends SingleChildStatelessWidget {
  final T Function(BuildContext context)? _create;
  final T? _value;
  T? _instance;

  Provider({
    required T Function(BuildContext context) create,
    super.child,
  })  : _create = create,
        _value = null;

  Provider.value({required T value, super.child})
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

/// Nests a list of providers so the last one in the list is the closest
/// ancestor to [child]. Keeps the tree flat at the call site:
///
/// ```dart
/// MultiProvider(
///   providers: [
///     Provider<AuthService>(create: (_) => AuthService()),
///     BlocProvider<AppCubit>(create: (_) => AppCubit()),
///   ],
///   child: MyWidget(),
/// )
/// ```
class MultiProvider extends StatelessWidget {
  final List<SingleChildStatelessWidget> providers;
  final Widget child;

  MultiProvider({required this.providers, required this.child});

  @override
  Widget build(BuildContext context) {
    Widget current = child;
    for (final p in providers.reversed) {
      p.child = current;
      current = p;
    }
    return current;
  }
}
