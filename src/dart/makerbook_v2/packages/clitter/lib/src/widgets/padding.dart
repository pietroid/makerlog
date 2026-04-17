import '../canvas.dart';
import '../constraints.dart';
import '../widget.dart';

/// Insets for a widget. All four sides are integers measured in
/// character cells.
class EdgeInsets {
  final int left;
  final int top;
  final int right;
  final int bottom;

  const EdgeInsets.only({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  /// Same inset on all four sides.
  const EdgeInsets.all(int value)
      : left = value,
        top = value,
        right = value,
        bottom = value;

  /// Symmetric: [horizontal] applied to left+right, [vertical] to top+bottom.
  const EdgeInsets.symmetric({int horizontal = 0, int vertical = 0})
      : left = horizontal,
        right = horizontal,
        top = vertical,
        bottom = vertical;

  int get horizontal => left + right;
  int get vertical => top + bottom;
}

/// Wraps a child and reserves blank cells on each side.
class Padding extends Widget {
  final EdgeInsets padding;
  final Widget child;

  Padding({required this.padding, required this.child});

  @override
  Size layout(BoxConstraints constraints) {
    // Shrink constraints by the padding before handing them to child.
    final innerConstraints = BoxConstraints(
      minWidth: (constraints.minWidth - padding.horizontal).clamp(0, 1 << 30),
      maxWidth: (constraints.maxWidth - padding.horizontal).clamp(0, 1 << 30),
      minHeight: (constraints.minHeight - padding.vertical).clamp(0, 1 << 30),
      maxHeight: (constraints.maxHeight - padding.vertical).clamp(0, 1 << 30),
    );
    final childSize = child.layout(innerConstraints);
    size = Size(
      constraints.constrainWidth(childSize.width + padding.horizontal),
      constraints.constrainHeight(childSize.height + padding.vertical),
    );
    return size;
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    child.paint(canvas, Offset(offset.dx + padding.left, offset.dy + padding.top));
  }
}
