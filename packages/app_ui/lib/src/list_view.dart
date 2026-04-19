import 'package:clitter/clitter.dart';

/// A very small scrollable-ish list. Renders the tail of [children]
/// that fits the available vertical space — newest items stay visible,
/// older ones fall off the top. It is enough for chat-log style use
/// without a proper virtual scroll.
class ListView extends Widget {
  final List<Widget> children;

  ListView({required this.children});

  List<Widget> _visible = const [];
  List<int> _heights = const [];

  @override
  Size layout(BoxConstraints constraints) {
    final measured = <Widget>[];
    final heights = <int>[];
    int used = 0;
    // Measure from the bottom up so the newest items always fit.
    for (int i = children.length - 1; i >= 0; i--) {
      final child = children[i];
      final remaining = constraints.maxHeight - used;
      if (remaining <= 0) break;
      final s = Framework.layoutChild(
        child,
        BoxConstraints(
          maxWidth: constraints.maxWidth,
          maxHeight: remaining,
        ),
      );
      if (s.height == 0) continue;
      measured.insert(0, child);
      heights.insert(0, s.height);
      used += s.height;
      if (used >= constraints.maxHeight) break;
    }
    _visible = measured;
    _heights = heights;
    size = Size(
      constraints.maxWidth,
      constraints.constrainHeight(used),
    );
    return size;
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    int dy = 0;
    for (int i = 0; i < _visible.length; i++) {
      _visible[i].paint(canvas, Offset(offset.dx, offset.dy + dy));
      dy += _heights[i];
    }
  }
}
