import '../app.dart';
import '../canvas.dart';
import '../constraints.dart';
import '../framework.dart';
import '../input.dart';
import '../widget.dart';

/// Holds scroll position for a [ListView]. Survives as long as the
/// caller keeps a reference to it.
class ScrollController {
  int offset = 0;

  bool _jumpToBottom = false;

  /// Call this after adding new content to force the list to the
  /// bottom on the next layout.
  void scrollToBottom() => _jumpToBottom = true;

  bool _takeJumpToBottom() {
    final v = _jumpToBottom;
    _jumpToBottom = false;
    return v;
  }
}

/// A scrollable list of widgets.
///
/// Renders [children] inside the available vertical space. By default
/// the viewport is pinned to the bottom so the newest items are
/// visible (chat-log style). The user can scroll with the arrow keys
/// or mouse wheel.
///
/// Pass a [ScrollController] to preserve scroll position across
/// rebuilds. When content grows and the viewport was already at the
/// bottom, it auto-scrolls to keep the newest item in view.
class ListView extends Widget {
  final List<Widget> children;
  final ScrollController? controller;

  ListView({required this.children, this.controller});

  List<Widget> _visible = const [];
  List<int> _heights = const [];
  int _topDy = 0;

  int get _scrollOffset => controller?.offset ?? 0;
  set _scrollOffset(int v) {
    if (controller != null) controller!.offset = v;
  }

  @override
  Size layout(BoxConstraints constraints) {
    final measured = <Widget>[];
    final heights = <int>[];
    int totalHeight = 0;

    // Measure every child and record cumulative offsets.
    final offsets = <int>[];
    for (final child in children) {
      final s = Framework.layoutChild(
        child,
        BoxConstraints(
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
        ),
      );
      if (s.height == 0) continue;
      measured.add(child);
      heights.add(s.height);
      offsets.add(totalHeight);
      totalHeight += s.height;
    }

    final viewportHeight = constraints.maxHeight;
    final maxScroll = totalHeight > viewportHeight
        ? totalHeight - viewportHeight
        : 0;

    var scrollOffset = _scrollOffset;

    // If the caller asked us to jump to bottom, honor it.
    if (controller?._takeJumpToBottom() == true) {
      scrollOffset = maxScroll;
    } else if (maxScroll == 0) {
      scrollOffset = 0;
    } else {
      // If the viewport was already at the bottom, stay pinned there
      // when new content arrives. Otherwise respect the user's scroll.
      final wasAtBottom = scrollOffset >= maxScroll;
      if (wasAtBottom || scrollOffset > maxScroll) {
        scrollOffset = maxScroll;
      }
    }

    _scrollOffset = scrollOffset;

    // Determine which children are visible starting at scrollOffset.
    final visible = <Widget>[];
    final visibleHeights = <int>[];
    int topDy = 0;
    bool foundFirst = false;
    for (int i = 0; i < measured.length; i++) {
      final childTop = offsets[i];
      final childBottom = childTop + heights[i];
      if (childBottom <= scrollOffset) continue;
      if (childTop >= scrollOffset + viewportHeight) break;
      if (!foundFirst) {
        topDy = childTop - scrollOffset;
        foundFirst = true;
      }
      visible.add(measured[i]);
      visibleHeights.add(heights[i]);
    }

    _visible = visible;
    _heights = visibleHeights;
    _topDy = topDy;
    size = Size(constraints.maxWidth, constraints.constrainHeight(viewportHeight));
    return size;
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    FocusManager.addKeyListener((event) {
      final maxScroll = _computeMaxScroll();
      switch (event.type) {
        case KeyType.arrowUp:
          _scrollOffset = (_scrollOffset - 1).clamp(0, _scrollOffset);
          _scrollOffset = _scrollOffset.clamp(0, maxScroll);
          App.scheduleRebuild();
        case KeyType.arrowDown:
          _scrollOffset = (_scrollOffset + 1).clamp(0, maxScroll);
          App.scheduleRebuild();
        default:
          break;
      }
    });

    FocusManager.addMouseListener((event) {
      final maxScroll = _computeMaxScroll();
      switch (event.kind) {
        case MouseEventKind.scrollUp:
          _scrollOffset = (_scrollOffset - 3).clamp(0, maxScroll);
          App.scheduleRebuild();
        case MouseEventKind.scrollDown:
          _scrollOffset = (_scrollOffset + 3).clamp(0, maxScroll);
          App.scheduleRebuild();
        default:
          break;
      }
    });

    int dy = _topDy;
    for (int i = 0; i < _visible.length; i++) {
      final child = _visible[i];
      final childOffset = Offset(offset.dx, offset.dy + dy);
      if (childOffset.dy + child.size.height > offset.dy &&
          childOffset.dy < offset.dy + size.height) {
        child.paint(canvas, childOffset);
      }
      dy += _heights[i];
    }
  }

  int _computeMaxScroll() {
    int totalHeight = 0;
    for (final child in children) {
      totalHeight += child.size.height;
    }
    final viewportHeight = size.height;
    return totalHeight > viewportHeight ? totalHeight - viewportHeight : 0;
  }
}
