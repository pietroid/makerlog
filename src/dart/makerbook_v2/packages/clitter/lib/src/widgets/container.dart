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
///   * Pass [double.infinity] as [width]/[height] to fill the incoming
///     max on that axis, exactly like Flutter.
///
/// The [color] is painted as a background — text drawn on top by a
/// descendant inherits it unless that text sets its own background.
class Container extends Widget {
  /// Width in character cells. Accepts an int, or [double.infinity] to
  /// fill the parent's incoming `maxWidth` (Flutter-style).
  final num? width;

  /// Height in character cells. Accepts an int, or [double.infinity]
  /// to fill the parent's incoming `maxHeight` (Flutter-style).
  final num? height;

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

    // Resolve `double.infinity` against the incoming max; otherwise
    // the width/height is already a finite int-valued num.
    final resolvedW = _resolve(width, constraints.maxWidth);
    final resolvedH = _resolve(height, constraints.maxHeight);

    final maxW = resolvedW ?? constraints.maxWidth;
    final maxH = resolvedH ?? constraints.maxHeight;

    int w;
    int h;
    if (_content != null) {
      // With a child: shrink-wrap unless explicit size overrides.
      final childSize = _content!.layout(
        BoxConstraints(maxWidth: maxW, maxHeight: maxH),
      );
      w = resolvedW ?? childSize.width;
      h = resolvedH ?? childSize.height;
    } else {
      // No child: fill whatever the parent gave us.
      w = resolvedW ?? constraints.maxWidth;
      h = resolvedH ?? constraints.maxHeight;
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

  // Turn a user-supplied width/height (which may be `double.infinity`
  // to request "fill the parent") into a concrete int, or null when
  // the user didn't specify anything.
  static int? _resolve(num? value, int parentMax) {
    if (value == null) return null;
    if (value == double.infinity) return parentMax;
    return value.toInt();
  }
}
