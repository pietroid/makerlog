import '../canvas.dart';
import '../color.dart';
import '../constraints.dart';
import '../text_style.dart';
import '../widget.dart';
import 'divider.dart';
import 'padding.dart';

/// A box-drawn border around a Container. Consumes 1 cell on each side.
class Border {
  final LineStyle style;
  final Color? color;

  const Border({this.style = LineStyle.thin, this.color});
}

/// A rectangle that can have a solid background [color], optional
/// explicit [width]/[height], an optional [border], and an optional
/// [child] with [padding].
///
/// Sizing rules (matching Flutter):
///   * With a [child]: shrink-wrap to the child's size (plus padding/border).
///   * Without a [child]: expand to fill the parent's constraints.
///   * Explicit [width]/[height] always wins over the above.
///   * Pass [double.infinity] as [width]/[height] to fill the incoming
///     max on that axis, exactly like Flutter.
class Container extends Widget {
  final num? width;
  final num? height;
  final Color? color;
  final EdgeInsets? padding;
  final Border? border;
  final Widget? child;

  Widget? _content;

  Container({
    this.width,
    this.height,
    this.color,
    this.padding,
    this.border,
    this.child,
  });

  int get _bw => border == null ? 0 : 1;

  @override
  Size layout(BoxConstraints constraints) {
    _content = (padding != null && child != null)
        ? Padding(padding: padding!, child: child!)
        : child;

    final resolvedW = _resolve(width, constraints.maxWidth);
    final resolvedH = _resolve(height, constraints.maxHeight);

    final maxW = resolvedW ?? constraints.maxWidth;
    final maxH = resolvedH ?? constraints.maxHeight;

    // Reserve border space before handing constraints to the child.
    final innerMaxW = (maxW - 2 * _bw).clamp(0, 1 << 30);
    final innerMaxH = (maxH - 2 * _bw).clamp(0, 1 << 30);

    int w;
    int h;
    if (_content != null) {
      final childSize = _content!.layout(
        BoxConstraints(maxWidth: innerMaxW, maxHeight: innerMaxH),
      );
      w = resolvedW ?? childSize.width + 2 * _bw;
      h = resolvedH ?? childSize.height + 2 * _bw;
    } else {
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
      canvas.fill(
        offset,
        size,
        ' ',
        style: TextStyle(backgroundColor: color),
      );
    }
    if (border != null) _paintBorder(canvas, offset);
    _content?.paint(
      canvas,
      Offset(offset.dx + _bw, offset.dy + _bw),
    );
  }

  void _paintBorder(Canvas canvas, Offset offset) {
    final b = border!;
    final s = b.style;
    final style = TextStyle(color: b.color, backgroundColor: color);
    final x0 = offset.dx;
    final y0 = offset.dy;
    final x1 = offset.dx + size.width - 1;
    final y1 = offset.dy + size.height - 1;

    if (size.width <= 0 || size.height <= 0) return;

    // Top & bottom edges.
    for (int x = x0 + 1; x < x1; x++) {
      canvas.drawText(x, y0, BoxChars.horizontal(s), style: style);
      canvas.drawText(x, y1, BoxChars.horizontal(s), style: style);
    }
    // Left & right edges.
    for (int y = y0 + 1; y < y1; y++) {
      canvas.drawText(x0, y, BoxChars.vertical(s), style: style);
      canvas.drawText(x1, y, BoxChars.vertical(s), style: style);
    }
    // Corners.
    canvas.drawText(x0, y0, BoxChars.topLeft(s), style: style);
    canvas.drawText(x1, y0, BoxChars.topRight(s), style: style);
    canvas.drawText(x0, y1, BoxChars.bottomLeft(s), style: style);
    canvas.drawText(x1, y1, BoxChars.bottomRight(s), style: style);
  }

  static int? _resolve(num? value, int parentMax) {
    if (value == null) return null;
    if (value == double.infinity) return parentMax;
    return value.toInt();
  }
}
