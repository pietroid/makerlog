/// A minimal stand-in for Flutter's BuildContext. Provides a
/// hierarchical provider lookup via [read] — walking up the parent
/// chain for the nearest value of the requested type.
///
/// Providers push values by returning a new context from their
/// [StatelessWidget.buildContext] override; the runtime threads
/// [BuildContext.current] through the layout pass so descendants
/// see their ancestors' provided values during `build()`.
class BuildContext {
  final BuildContext? _parent;
  final Type? _type;
  final Object? _value;

  const BuildContext()
      : _parent = null,
        _type = null,
        _value = null;

  const BuildContext._child(this._parent, this._type, this._value);

  /// Returns a new context that provides [value] under type [T] to
  /// descendants, keeping this context as the parent.
  BuildContext provide<T>(T value) => BuildContext._child(this, T, value);

  /// Walk up the provider chain and return the nearest value of type
  /// [T]. Throws [StateError] if none is found.
  T read<T>() {
    BuildContext? c = this;
    while (c != null) {
      if (c._type == T && c._value is T) return c._value as T;
      c = c._parent;
    }
    throw StateError('No provider for $T found in BuildContext');
  }

  /// The context currently in effect during the ongoing layout pass.
  /// `StatelessWidget.layout` swaps this around its `build()` call so
  /// children automatically inherit their parents' providers.
  static BuildContext current = const BuildContext();
}
