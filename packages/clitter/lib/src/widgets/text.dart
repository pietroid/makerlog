import '../canvas.dart';
import '../constraints.dart';
import '../text_style.dart';
import '../widget.dart';

/// Single- or multi-line text. Wraps by character when the content
/// is wider than the parent's max width, and preserves explicit
/// `\n` breaks in the source string.
///
/// An optional [style] controls colour, background colour, bold and
/// italic. A null attribute on the style means "don't override" —
/// handy for drawing text over a coloured [Container] without
/// repeating the background colour.
/// Horizontal alignment of each line within the widget's width.
/// When set, the widget expands to the parent's max width so the
/// alignment has room to operate.
enum TextAlign { start, center, end }

class Text extends Widget {
  final String data;
  final TextStyle? style;
  final TextAlign? align;

  List<String> _lines = const [];

  Text(this.data, {this.style, this.align});

  @override
  Size layout(BoxConstraints constraints) {
    _lines = _wrap(data, constraints.maxWidth);

    int widest = 0;
    for (final line in _lines) {
      if (line.length > widest) widest = line.length;
    }

    // Alignment needs a canvas wider than the content; when an align
    // is specified, stretch to the max width the parent allows.
    final targetWidth = align == null ? widest : constraints.maxWidth;

    size = Size(
      constraints.constrainWidth(targetWidth),
      constraints.constrainHeight(_lines.length),
    );
    return size;
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    for (int i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      int dx;
      switch (align ?? TextAlign.start) {
        case TextAlign.start:
          dx = 0;
          break;
        case TextAlign.center:
          dx = (size.width - line.length) ~/ 2;
          break;
        case TextAlign.end:
          dx = size.width - line.length;
          break;
      }
      canvas.drawText(offset.dx + dx, offset.dy + i, line, style: style);
    }
  }

  // Hard-wrap at [width]. Honours explicit newlines so the caller
  // keeps intentional line breaks. A smarter word-wrap could live
  // here later.
  static List<String> _wrap(String text, int width) {
    if (width <= 0) return const [];
    final result = <String>[];
    for (final paragraph in text.split('\n')) {
      if (paragraph.isEmpty) {
        result.add('');
        continue;
      }
      for (int i = 0; i < paragraph.length; i += width) {
        final end = (i + width) > paragraph.length ? paragraph.length : i + width;
        result.add(paragraph.substring(i, end));
      }
    }
    return result;
  }
}
