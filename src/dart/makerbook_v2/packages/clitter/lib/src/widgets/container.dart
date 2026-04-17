import '../canvas.dart';
import '../color.dart';
import '../constraints.dart';
import '../text_style.dart';
import '../widget.dart';
import 'padding.dart';

/// A rectangle that can have a solid background [color], optional
/// explicit [width]/[height], and an optional [child] with [padding].
///
/// Sizing rules (matching Flutter):
///   * With a [child]: shrink-wrap to the child's size (plus padding).
///   * Without a [child]: expand to fill the parent's constraints.
///   * Explicit [width]/[height] always wins over the above.
///
/// The [color] is painted as a background — text drawn on top by a
/// descendant inherits it unless that text sets its own background.
class Container extends Widget {
  final int? width;
  final int? height;
  final Color? color;
  final EdgeInsets? padding;
  final Widget? child;

  /// Effective child after wrapping in [Padding] if needed. Cached
  /// between layout and paint so we don't rebuild the Padding widget.
  Widget? _content;

  Container({
    this.width,
    this.height,
    this.color,
    this.padding,
    this.child,
  });

  @override
  Size layout(BoxConstraints constraints) {
    _content = (padding != null && child != null)
        ? Padding(padding: padding!, child: child!)
        : child;

    // Clamp explicit size hints into whatever our parent offered.
    final maxW = width ?? constraints.maxWidth;
    final maxH = height ?? constraints.maxHeight;

    int w;
    int h;
    if (_content != null) {
      // With a child: shrink-wrap unless explicit size overrides.
      final childSize = _content!.layout(
        BoxConstraints(maxWidth: maxW, maxHeight: maxH),
      );
      w = width ?? childSize.width;
      h = height ?? childSize.height;
    } else {
      // No child: fill whatever the parent gave us.
      w = width ?? constraints.maxWidth;
      h = height ?? constraints.maxHeight;
    }

    size = Size(
      constraints.constrainWidth(w),
      constraints.constrainHeight(h),
    );
    return size;
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    if (color != null) {
      // Solid background. Spaces carry the colour; if a child paints
      // text over this area, the merge rule in Canvas preserves the
      // background for cells the child doesn't explicitly restyle.
      canvas.fill(
        offset,
        size,
        ' ',
        style: TextStyle(backgroundColor: color),
      );
    }
    _content?.paint(canvas, offset);
  }
}
