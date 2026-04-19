import '../canvas.dart';
import '../constraints.dart';
import '../framework.dart';
import '../widget.dart';
import 'expanded.dart';
import 'flex.dart';

/// Lays out [children] vertically. Each child gets the column's full
/// width. [Expanded] children share the leftover height after all
/// fixed-size children are placed.
///
/// Two-pass layout:
///   1. Measure fixed children with the remaining height budget.
///   2. Divide what's left between Expanded children by flex weight.
class Column extends Widget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  Column({
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Size layout(BoxConstraints constraints) {
    int remaining = constraints.maxHeight;
    int totalFlex = 0;
    int maxChildWidth = 0;

    // Pass 1: fixed-size children.
    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      if (child is Expanded) {
        totalFlex += child.flex;
        continue;
      }
      final s = Framework.layoutChild(
        child,
        BoxConstraints(
          maxWidth: constraints.maxWidth,
          maxHeight: remaining < 0 ? 0 : remaining,
        ),
        siblingIndex: i,
      );
      remaining -= s.height;
      if (s.width > maxChildWidth) maxChildWidth = s.width;
    }

    // Pass 2: expanded children share `remaining`.
    if (totalFlex > 0) {
      int used = 0;
      int placed = 0;
      final expandedCount = children.whereType<Expanded>().length;
      int seen = 0;
      for (int i = 0; i < children.length; i++) {
        final child = children[i];
        if (child is! Expanded) continue;
        // Last Expanded absorbs the rounding remainder so totals line up.
        final isLast = seen == expandedCount - 1;
        seen++;
        final h = isLast
            ? (remaining - used).clamp(0, remaining)
            : (remaining * child.flex ~/ totalFlex).clamp(0, remaining);
        used += h;
        placed++;
        final s = Framework.layoutChild(
          child,
          BoxConstraints(
            minWidth: 0,
            maxWidth: constraints.maxWidth,
            minHeight: h,
            maxHeight: h,
          ),
          siblingIndex: i,
        );
        if (s.width > maxChildWidth) maxChildWidth = s.width;
      }
      // Silence unused-var lint while still documenting intent.
      assert(placed == expandedCount);
    }

    final totalHeight =
        children.fold<int>(0, (sum, c) => sum + c.size.height);

    // When the caller wants non-start alignment we expand to the
    // parent's max so there's room for the alignment to operate.
    final heightForMain = mainAxisAlignment == MainAxisAlignment.start
        ? totalHeight
        : constraints.maxHeight;
    final widthForCross = crossAxisAlignment == CrossAxisAlignment.start
        ? maxChildWidth
        : (maxChildWidth > constraints.maxWidth
            ? constraints.maxWidth
            : maxChildWidth);

    size = Size(
      constraints.constrainWidth(widthForCross),
      constraints.constrainHeight(heightForMain),
    );
    return size;
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    final totalChildHeight =
        children.fold<int>(0, (sum, c) => sum + c.size.height);
    final freeMain = size.height - totalChildHeight;

    int leading;
    int between;
    switch (mainAxisAlignment) {
      case MainAxisAlignment.start:
        leading = 0;
        between = 0;
        break;
      case MainAxisAlignment.center:
        leading = freeMain ~/ 2;
        between = 0;
        break;
      case MainAxisAlignment.end:
        leading = freeMain;
        between = 0;
        break;
      case MainAxisAlignment.spaceBetween:
        leading = 0;
        between = children.length > 1 ? freeMain ~/ (children.length - 1) : 0;
        break;
      case MainAxisAlignment.spaceAround:
        between = children.isNotEmpty ? freeMain ~/ children.length : 0;
        leading = between ~/ 2;
        break;
      case MainAxisAlignment.spaceEvenly:
        between = freeMain ~/ (children.length + 1);
        leading = between;
        break;
    }
    if (leading < 0) leading = 0;
    if (between < 0) between = 0;

    int dy = leading;
    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      int dx;
      switch (crossAxisAlignment) {
        case CrossAxisAlignment.start:
          dx = 0;
          break;
        case CrossAxisAlignment.center:
          dx = (size.width - child.size.width) ~/ 2;
          break;
        case CrossAxisAlignment.end:
          dx = size.width - child.size.width;
          break;
      }
      if (dx < 0) dx = 0;
      child.paint(canvas, Offset(offset.dx + dx, offset.dy + dy));
      dy += child.size.height;
      if (i != children.length - 1) dy += between;
    }
  }
}
