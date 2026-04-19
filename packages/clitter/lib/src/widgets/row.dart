import '../canvas.dart';
import '../constraints.dart';
import '../framework.dart';
import '../widget.dart';
import 'expanded.dart';
import 'flex.dart';

/// Horizontal twin of [Column]. Lays out [children] left-to-right,
/// giving each fixed child its natural width and letting [Expanded]
/// children split the remainder by flex weight.
class Row extends Widget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  Row({
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Size layout(BoxConstraints constraints) {
    int remaining = constraints.maxWidth;
    int totalFlex = 0;
    int maxChildHeight = 0;

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
          maxWidth: remaining < 0 ? 0 : remaining,
          maxHeight: constraints.maxHeight,
        ),
        siblingIndex: i,
      );
      remaining -= s.width;
      if (s.height > maxChildHeight) maxChildHeight = s.height;
    }

    // Pass 2: expanded children share `remaining` width.
    if (totalFlex > 0) {
      int used = 0;
      final expandedCount = children.whereType<Expanded>().length;
      int seen = 0;
      for (int i = 0; i < children.length; i++) {
        final child = children[i];
        if (child is! Expanded) continue;
        final isLast = seen == expandedCount - 1;
        seen++;
        final w = isLast
            ? (remaining - used).clamp(0, remaining)
            : (remaining * child.flex ~/ totalFlex).clamp(0, remaining);
        used += w;
        final s = Framework.layoutChild(
          child,
          BoxConstraints(
            minWidth: w,
            maxWidth: w,
            minHeight: 0,
            maxHeight: constraints.maxHeight,
          ),
          siblingIndex: i,
        );
        if (s.height > maxChildHeight) maxChildHeight = s.height;
      }
    }

    final totalWidth = children.fold<int>(0, (sum, c) => sum + c.size.width);

    final widthForMain = mainAxisAlignment == MainAxisAlignment.start
        ? totalWidth
        : constraints.maxWidth;
    final heightForCross = crossAxisAlignment == CrossAxisAlignment.start
        ? maxChildHeight
        : (maxChildHeight > constraints.maxHeight
            ? constraints.maxHeight
            : maxChildHeight);

    size = Size(
      constraints.constrainWidth(widthForMain),
      constraints.constrainHeight(heightForCross),
    );
    return size;
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    final totalChildWidth =
        children.fold<int>(0, (sum, c) => sum + c.size.width);
    final freeMain = size.width - totalChildWidth;

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

    int dx = leading;
    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      int dy;
      switch (crossAxisAlignment) {
        case CrossAxisAlignment.start:
          dy = 0;
          break;
        case CrossAxisAlignment.center:
          dy = (size.height - child.size.height) ~/ 2;
          break;
        case CrossAxisAlignment.end:
          dy = size.height - child.size.height;
          break;
      }
      if (dy < 0) dy = 0;
      child.paint(canvas, Offset(offset.dx + dx, offset.dy + dy));
      dx += child.size.width;
      if (i != children.length - 1) dx += between;
    }
  }
}
