import '../canvas.dart';
import '../constraints.dart';
import '../widget.dart';

/// Fixed-size container. Either:
///   * holds a [child] and forces it to [width] x [height], OR
///   * takes up blank space when used for margin / separation.
class SizedBox extends Widget {
  final int? width;
  final int? height;
  final Widget? child;

  SizedBox({this.width, this.height, this.child});

  /// Convenience: a vertical gap.
  SizedBox.vertical(int h)
      : width = null,
        height = h,
        child = null;

  /// Convenience: a horizontal gap.
  SizedBox.horizontal(int w)
      : width = w,
        height = null,
        child = null;

  @override
  Size layout(BoxConstraints constraints) {
    final w = width ?? constraints.maxWidth;
    final h = height ?? constraints.maxHeight;
    final finalSize = Size(
      constraints.constrainWidth(w),
      constraints.constrainHeight(h),
    );
    child?.layout(BoxConstraints.tight(finalSize));
    size = finalSize;
    return size;
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    child?.paint(canvas, offset);
  }
}
