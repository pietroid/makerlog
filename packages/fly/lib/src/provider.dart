import 'build_context.dart';
import 'framework.dart';
import 'widget.dart';

/// Marker interface for widgets that have a single mutable [child]
/// slot so [MultiProvider] can nest them. Both
/// [SingleChildStatelessWidget] (plain providers) and
/// [SingleChildStatefulWidget] (providers that own mutable state, like
/// blocs) implement this, so `MultiProvider` doesn't care which kind
/// you hand it.
abstract class SingleChildWidget implements Widget {
  Widget? child;
}

/// Base for stateless widgets that wrap a single child subtree. The
/// child is mutable so [MultiProvider] can re-link providers into a
/// nested chain at build time.
abstract class SingleChildStatelessWidget extends StatelessWidget
    implements SingleChildWidget {
  @override
  Widget? child;
  SingleChildStatelessWidget({this.child});

  @override
  Widget build(BuildContext context) {
    assert(child != null, '$runtimeType was built without a child');
    return child!;
  }
}

/// Stateful analogue: a [StatefulWidget] that carries a mutable
/// single-child slot. Providers that need to own a lifecycle object
/// (a bloc, a repository, anything that closes/disposes) extend this
/// so their [State] can survive rebuilds via the [Framework] cache.
abstract class SingleChildStatefulWidget extends StatefulWidget
    implements SingleChildWidget {
  @override
  Widget? child;
  SingleChildStatefulWidget({this.child, super.key});
}

/// Exposes a plain value (service, repository, config — anything
/// non-bloc) to descendants via [BuildContext.read].
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
/// Stateful so the `create`-produced value survives rebuilds; without
/// persistent state the widget would allocate a fresh instance every
/// frame.
class Provider<T extends Object> extends SingleChildStatefulWidget {
  final T Function(BuildContext context)? _create;
  final T? _value;

  Provider({
    required T Function(BuildContext context) create,
    super.child,
    super.key,
  })  : _create = create,
        _value = null;

  Provider.value({required T value, super.child, super.key})
      : _create = null,
        _value = value;

  @override
  State<Provider<T>> createState() => _ProviderState<T>();
}

class _ProviderState<T extends Object> extends State<Provider<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget._value ?? widget._create!(context);
  }

  @override
  BuildContext buildContext(BuildContext parent) =>
      parent.provide<T>(_value);

  @override
  Widget build(BuildContext context) {
    assert(widget.child != null, 'Provider was built without a child');
    return widget.child!;
  }
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
  final List<SingleChildWidget> providers;
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
