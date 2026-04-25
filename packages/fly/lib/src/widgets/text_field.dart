import '../canvas.dart';
import '../constraints.dart';
import '../input.dart';
import '../text_editing_controller.dart';
import '../text_style.dart';
import '../widget.dart';

/// Text input backed by a [TextEditingController].
///
/// Styling: [style] is applied to the field as a whole — importantly,
/// it's also used to fill the entire row so the background colour
/// extends to the end of the field, not just under the text the user
/// has typed. [placeholderStyle] is applied when the field is empty;
/// if omitted it falls back to [style] with a dim look.
///
/// [maxLines] controls vertical expansion:
///   * `1` (default) — single-line, fixed height.
///   * `null` — grows to fit all wrapped text (unlimited).
///
/// [multiline] changes Enter behaviour: when true, Enter inserts a
/// newline; use Ctrl+D to fire [onSubmit].
///
/// Painting claims focus for the current frame. The last TextField to
/// paint wins — fine for single-input screens; multi-input focus
/// traversal is a future task.
class TextField extends Widget {
  final TextEditingController controller;
  final String? placeholder;
  final void Function(String text)? onSubmit;

  /// Style applied to user-entered text and the field background.
  final TextStyle? style;

  /// Style applied to the placeholder. Defaults to [style] if null.
  final TextStyle? placeholderStyle;

  /// Maximum number of visual lines. `null` means unlimited.
  final int? maxLines;

  /// When true, Enter inserts `\n` and Ctrl+D triggers [onSubmit].
  final bool multiline;

  TextField({
    required this.controller,
    this.placeholder,
    this.onSubmit,
    this.style,
    this.placeholderStyle,
    this.maxLines = 1,
    this.multiline = false,
  });

  @override
  Size layout(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final text = controller.text;
    final lines = _lineCount(text, width);
    final clamped = maxLines == null ? lines : lines.clamp(1, maxLines!);
    size = Size(width, constraints.constrainHeight(clamped));
    return size;
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    FocusManager.request(
      controller,
      onSubmit: onSubmit,
      multiline: multiline,
    );

    if (style != null) {
      canvas.fill(offset, size, ' ', style: style);
    }

    final text = controller.text;
    final width = size.width;

    if (text.isEmpty && placeholder != null) {
      canvas.drawText(
        offset.dx,
        offset.dy,
        placeholder!,
        style: placeholderStyle ?? style,
      );
    } else {
      _paintMultilineText(canvas, text, width, offset, style);
    }

    final (cursorLine, cursorCol) = _cursorPosition(text, width, controller.cursor);
    FocusManager.cursor = Offset(
      offset.dx + cursorCol,
      offset.dy + cursorLine,
    );
  }

  /// Renders [text] line-wrapped at [width] starting from [offset].
  static void _paintMultilineText(
    Canvas canvas,
    String text,
    int width,
    Offset offset,
    TextStyle? style,
  ) {
    int line = 0;
    int col = 0;
    for (final ch in text.split('')) {
      if (ch == '\n') {
        line++;
        col = 0;
      } else {
        if (col >= width) {
          line++;
          col = 0;
        }
        canvas.drawText(offset.dx + col, offset.dy + line, ch, style: style);
        col++;
      }
    }
  }

  /// Number of visual lines [text] occupies when wrapped at [width].
  static int _lineCount(String text, int width) {
    int line = 0;
    int col = 0;
    int maxLine = 0;
    for (final ch in text.split('')) {
      if (ch == '\n') {
        line++;
        col = 0;
      } else {
        if (col >= width) {
          line++;
          col = 0;
        }
        col++;
      }
      if (line > maxLine) maxLine = line;
    }
    return maxLine + 1;
  }

  /// Maps a character [cursor] index to (line, col) in wrapped space.
  static (int line, int col) _cursorPosition(String text, int width, int cursor) {
    int line = 0;
    int col = 0;
    int idx = 0;
    for (final ch in text.split('')) {
      if (idx == cursor) break;
      if (ch == '\n') {
        line++;
        col = 0;
      } else {
        if (col >= width) {
          line++;
          col = 0;
        }
        col++;
      }
      idx++;
    }
    if (col >= width) {
      line++;
      col = 0;
    }
    return (line, col);
  }
}
