import '../canvas.dart';
import '../constraints.dart';
import '../widget.dart';
import 'expanded.dart';

/// Lays out [children] vertically. Each child gets the column's full
/// width. [Expanded] children share the leftover height after all
/// fixed-size children are placed.
///
/// Two-pass layout:
///   1. Measure fixed children with the remaining height budget.
///   2. Divide what's left between Expanded children by flex weight.
class Column extends Widget {
  final List<Widget> children;

  Column({required this.children});

  @override
  Size layout(BoxConstraints constraints) {
    int remaining = constraints.maxHeight;
    int totalFlex = 0;
    int maxChildWidth = 0;

    // Pass 1: fixed-size children.
    for (final child in children) {
      if (child is Expanded) {
        totalFlex += child.flex;
        continue;
      }
      final s = child.layout(
        BoxConstraints(
          maxWidth: constraints.maxWidth,
          maxHeight: remaining < 0 ? 0 : remaining,
        ),
      );
      remaining -= s.height;
      if (s.width > maxChildWidth) maxChildWidth = s.width;
    }

    // Pass 2: expanded children share `remaining`.
    if (totalFlex > 0) {
      int used = 0;
      int placed = 0;
      final expanded = children.whereType<Expanded>().toList();
      for (int i = 0; i < expanded.length; i++) {
        final exp = expanded[i];
        // Last Expanded absorbs the rounding remainder so totals line up.
        final isLast = i == expanded.length - 1;
        final h = isLast
            ? (remaining - used).clamp(0, remaining)
            : (remaining * exp.flex ~/ totalFlex).clamp(0, remaining);
        used += h;
        placed++;
        final s = exp.layout(
          BoxConstraints(
            minWidth: 0,
            maxWidth: constraints.maxWidth,
            minHeight: h,
            maxHeight: h,
          ),
        );
        if (s.width > maxChildWidth) maxChildWidth = s.width;
      }
      // Silence unused-var lint while still documenting intent.
      assert(placed == expanded.length);
    }

    final totalHeight =
        children.fold<int>(0, (sum, c) => sum + c.size.height);

    size = Size(
      constraints.constrainWidth(maxChildWidth),
      constraints.constrainHeight(totalHeight),
    );
    return size;
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    int dy = 0;
    for (final child in children) {
      child.paint(canvas, Offset(offset.dx, offset.dy + dy));
      dy += child.size.height;
    }
  }
}
