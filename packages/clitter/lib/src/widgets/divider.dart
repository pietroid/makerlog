import '../canvas.dart';
import '../color.dart';
import '../constraints.dart';
import '../text_style.dart';
import '../widget.dart';

/// Visual weight for box-drawing characters.
enum LineStyle { thin, thick, double }

/// A 1-cell-thick line that fills the cross-axis extent given by its
/// parent. Use [Divider.horizontal] for a full-width rule and
/// [Divider.vertical] for a full-height one.
class Divider extends Widget {
  final Axis axis;
  final LineStyle style;
  final Color? color;

  Divider({
    this.axis = Axis.horizontal,
    this.style = LineStyle.thin,
    this.color,
  });

  Divider.horizontal({LineStyle style = LineStyle.thin, Color? color})
      : this(axis: Axis.horizontal, style: style, color: color);

  Divider.vertical({LineStyle style = LineStyle.thin, Color? color})
      : this(axis: Axis.vertical, style: style, color: color);

  @override
  Size layout(BoxConstraints constraints) {
    size = axis == Axis.horizontal
        ? Size(constraints.maxWidth, constraints.constrainHeight(1))
        : Size(constraints.constrainWidth(1), constraints.maxHeight);
    return size;
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    final ch = axis == Axis.horizontal
        ? BoxChars.horizontal(style)
        : BoxChars.vertical(style);
    canvas.fill(offset, size, ch, style: TextStyle(color: color));
  }
}

enum Axis { horizontal, vertical }

/// Unicode box-drawing glyphs grouped by [LineStyle]. Used by [Divider]
/// and by Container borders.
class BoxChars {
  static String horizontal(LineStyle s) => switch (s) {
        LineStyle.thin => '─',
        LineStyle.thick => '━',
        LineStyle.double => '═',
      };

  static String vertical(LineStyle s) => switch (s) {
        LineStyle.thin => '│',
        LineStyle.thick => '┃',
        LineStyle.double => '║',
      };

  static String topLeft(LineStyle s) => switch (s) {
        LineStyle.thin => '┌',
        LineStyle.thick => '┏',
        LineStyle.double => '╔',
      };

  static String topRight(LineStyle s) => switch (s) {
        LineStyle.thin => '┐',
        LineStyle.thick => '┓',
        LineStyle.double => '╗',
      };

  static String bottomLeft(LineStyle s) => switch (s) {
        LineStyle.thin => '└',
        LineStyle.thick => '┗',
        LineStyle.double => '╚',
      };

  static String bottomRight(LineStyle s) => switch (s) {
        LineStyle.thin => '┘',
        LineStyle.thick => '┛',
        LineStyle.double => '╝',
      };
}
