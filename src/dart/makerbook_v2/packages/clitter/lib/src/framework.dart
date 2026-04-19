import 'app.dart';
import 'build_context.dart';
import 'canvas.dart';
import 'constraints.dart';
import 'widget.dart';

/// Clitter's mini element-tree.
///
/// Widget instances are thrown away and recreated every frame, so any
/// long-lived state has to live somewhere else. [Framework] keeps a
/// map of [State] objects keyed by the widget's position in the tree,
/// so a [StatefulWidget]'s state survives rebuilds in the same place —
/// the same trick Flutter's Element tree plays, just implemented as a
/// cache instead of a parallel tree.
///
/// Sibling disambiguation is position-based by default; pass a `key`
/// on the StatefulWidget to make it survive reordering.
///
/// Widgets with children MUST route layout through
/// [Framework.layoutChild] instead of calling `child.layout(...)`
/// directly — otherwise their descendants never appear on the path
/// and their state won't be found.
class Framework {
  static final List<_PathSegment> _path = [];
  static final Map<_Path, State> _states = {};
  static final Set<_Path> _visited = {};

  /// Layout [child] at the given [constraints], recording its position
  /// on the path so any nested [StatefulWidget]s can find their state.
  /// [siblingIndex] disambiguates positional siblings with the same type.
  static Size layoutChild(
    Widget child,
    BoxConstraints constraints, {
    int siblingIndex = 0,
  }) {
    final key = child is StatefulWidget && child.key != null
        ? child.key!
        : siblingIndex;
    _path.add(_PathSegment(child.runtimeType, key));
    try {
      return child.layout(constraints);
    } finally {
      _path.removeLast();
    }
  }

  /// Obtain (or create) the [State] for [widget] at the current path,
  /// running the appropriate lifecycle callbacks. Called by
  /// [StatefulWidget.layout] — user code shouldn't need to touch it.
  static S obtainState<W extends StatefulWidget, S extends State<W>>(
    W widget,
    S Function() create,
  ) {
    final p = _snapshotPath();
    _visited.add(p);
    final existing = _states[p];
    if (existing != null &&
        existing._widget.runtimeType == widget.runtimeType) {
      final old = existing._widget as W;
      existing._widget = widget;
      existing.didUpdateWidget(old);
      return existing as S;
    }
    if (existing != null) existing.dispose();
    final fresh = create();
    fresh._widget = widget;
    fresh._context = BuildContext.current;
    _states[p] = fresh;
    fresh.initState();
    return fresh;
  }

  /// Called by the runtime once per frame, after layout+paint. Any
  /// [State] that wasn't visited this frame belongs to a widget that
  /// was removed from the tree — dispose and drop it.
  static void endFrame() {
    final stale = <_Path>[];
    for (final entry in _states.entries) {
      if (!_visited.contains(entry.key)) stale.add(entry.key);
    }
    for (final k in stale) {
      _states[k]!.dispose();
      _states.remove(k);
    }
    _visited.clear();
  }

  static _Path _snapshotPath() =>
      _Path(List<_PathSegment>.unmodifiable(_path));
}

class _PathSegment {
  final Type type;
  final Object key;
  const _PathSegment(this.type, this.key);

  @override
  bool operator ==(Object other) =>
      other is _PathSegment && other.type == type && other.key == key;

  @override
  int get hashCode => Object.hash(type, key);
}

class _Path {
  final List<_PathSegment> segments;
  _Path(this.segments);

  @override
  bool operator ==(Object other) {
    if (other is! _Path) return false;
    if (other.segments.length != segments.length) return false;
    for (int i = 0; i < segments.length; i++) {
      if (segments[i] != other.segments[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(segments);
}

/// A widget that keeps state across rebuilds via a paired [State]
/// object. Mirrors Flutter's StatefulWidget: the widget is a cheap,
/// throwaway config; the [State] holds the long-lived data and does
/// the subscribing / building.
///
/// Pass a [key] if this widget can move between positions among
/// siblings — otherwise identity is tracked positionally.
abstract class StatefulWidget extends Widget {
  final Object? key;
  Widget? _built;

  StatefulWidget({this.key});

  /// Factory for the paired [State]. Called once per (path, widget
  /// type); subsequent rebuilds reuse the existing instance.
  State createState();

  @override
  Size layout(BoxConstraints constraints) {
    final state = Framework.obtainState(this, createState);
    final parentContext = BuildContext.current;
    final ctx = state.buildContext(parentContext);
    state._context = ctx;
    BuildContext.current = ctx;
    try {
      _built = state.build(ctx);
      final s = Framework.layoutChild(_built!, constraints);
      size = s;
      return s;
    } finally {
      BuildContext.current = parentContext;
    }
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    _built?.paint(canvas, offset);
  }
}

/// The persistent half of a [StatefulWidget]. Holds mutable fields,
/// subscriptions, and any other data that must survive rebuilds.
///
/// Lifecycle:
///   * [initState] — first layout at this path.
///   * [didUpdateWidget] — subsequent rebuilds where the config changed.
///   * [build] — every rebuild.
///   * [dispose] — the widget was removed from the tree.
abstract class State<T extends StatefulWidget> {
  late T _widget;
  BuildContext? _context;

  T get widget => _widget;
  BuildContext get context => _context!;

  /// Called exactly once, immediately after the framework creates
  /// this State. Subscribe to streams, capture BLoCs, etc. here.
  void initState() {}

  /// Called when the widget at this path is rebuilt with a new
  /// instance of the same type. [oldWidget] is the previous config.
  void didUpdateWidget(T oldWidget) {}

  /// Called when this widget is removed from the tree. Cancel
  /// subscriptions, close streams.
  void dispose() {}

  /// Ask the runtime to rebuild. Matches Flutter's API — the `fn`
  /// runs synchronously so callers can mutate fields inside it and
  /// know the next [build] will see the new values.
  void setState(void Function() fn) {
    fn();
    App.scheduleRebuild();
  }

  /// Subclass hook: returns the [BuildContext] to be used by this
  /// widget's descendants. Overridden by providers to inject values.
  BuildContext buildContext(BuildContext parent) => parent;

  /// Returns the widget subtree. Called on every rebuild.
  Widget build(BuildContext context);
}
