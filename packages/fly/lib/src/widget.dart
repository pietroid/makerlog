import 'build_context.dart';
import 'canvas.dart';
import 'constraints.dart';
import 'framework.dart';

/// Base class for everything the runtime can render.
///
/// Unlike Flutter, fly widgets are not immutable render-object
/// factories — they're re-used directly as the layout node. Each frame
/// the runtime calls [layout] to compute a size (stored in [size])
/// and then [paint] to draw. This keeps the framework small at the
/// cost of not getting Flutter's element-tree reconciliation; for a
/// terminal UI re-laying out on every keystroke is cheap enough.
abstract class Widget {
  /// Most recent layout result. Parents read this after calling
  /// [layout] to position their children.
  Size size = const Size.zero();

  /// Compute and store [size] given parent [constraints]. Implementers
  /// must respect the constraints — the runtime assumes the returned
  /// size fits inside them.
  Size layout(BoxConstraints constraints);

  /// Paint into [canvas] at [offset]. Called after [layout]; may
  /// assume [size] is set.
  void paint(Canvas canvas, Offset offset);
}

/// A widget whose layout is entirely defined by another widget,
/// obtained by calling [build]. This is the fly analogue of
/// Flutter's StatelessWidget.
abstract class StatelessWidget extends Widget {
  Widget? _built;

  /// Describe this widget's UI in terms of other widgets.
  Widget build(BuildContext context);

  /// Hook for providers to inject values into the context seen by
  /// this widget's `build()` and its descendants. The default is the
  /// ancestor context unchanged.
  BuildContext buildContext(BuildContext parent) => parent;

  @override
  Size layout(BoxConstraints constraints) {
    // Rebuild every frame: picks up BLoC state, resize, etc.
    final parentContext = BuildContext.current;
    final ctx = buildContext(parentContext);
    BuildContext.current = ctx;
    try {
      _built = build(ctx);
      final childSize = Framework.layoutChild(_built!, constraints);
      size = childSize;
      return size;
    } finally {
      BuildContext.current = parentContext;
    }
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    _built?.paint(canvas, offset);
  }
}
