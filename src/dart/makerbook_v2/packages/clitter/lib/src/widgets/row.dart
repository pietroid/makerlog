import '../canvas.dart';
import '../constraints.dart';
import '../widget.dart';
import 'expanded.dart';

/// Horizontal twin of [Column]. Lays out [children] left-to-right,
/// giving each fixed child its natural width and letting [Expanded]
/// children split the remainder by flex weight.
class Row extends Widget {
  final List<Widget> children;

  Row({required this.children});

  @override
  Size layout(BoxConstraints constraints) {
    int remaining = constraints.maxWidth;
    int totalFlex = 0;
    int maxChildHeight = 0;

    // Pass 1: fixed-size children.
    for (final child in children) {
      if (child is Expanded) {
        totalFlex += child.flex;
        continue;
      }
      final s = child.layout(
        BoxConstraints(
          maxWidth: remaining < 0 ? 0 : remaining,
          maxHeight: constraints.maxHeight,
        ),
      );
      remaining -= s.width;
      if (s.height > maxChildHeight) maxChildHeight = s.height;
    }

    // Pass 2: expanded children share `remaining` width.
    if (totalFlex > 0) {
      int used = 0;
      final expanded = children.whereType<Expanded>().toList();
      for (int i = 0; i < expanded.length; i++) {
        final exp = expanded[i];
        final isLast = i == expanded.length - 1;
        final w = isLast
            ? (remaining - used).clamp(0, remaining)
            : (remaining * exp.flex ~/ totalFlex).clamp(0, remaining);
        used += w;
        final s = exp.layout(
          BoxConstraints(
            minWidth: w,
            maxWidth: w,
            minHeight: 0,
            maxHeight: constraints.maxHeight,
          ),
        );
        if (s.height > maxChildHeight) maxChildHeight = s.height;
      }
    }

    final totalWidth = children.fold<int>(0, (sum, c) => sum + c.size.width);

    size = Size(
      constraints.constrainWidth(totalWidth),
      constraints.constrainHeight(maxChildHeight),
    );
    return size;
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    int dx = 0;
    for (final child in children) {
      child.paint(canvas, Offset(offset.dx + dx, offset.dy));
      dx += child.size.width;
    }
  }
}
