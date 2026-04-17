import '../canvas.dart';
import '../constraints.dart';
import '../input.dart';
import '../text_editing_controller.dart';
import '../text_style.dart';
import '../widget.dart';

/// Single-line text input backed by a [TextEditingController].
///
/// Styling: [style] is applied to the field as a whole — importantly,
/// it's also used to fill the entire row so the background colour
/// extends to the end of the field, not just under the text the user
/// has typed. [placeholderStyle] is applied when the field is empty;
/// if omitted it falls back to [style] with a dim look.
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

  TextField({
    required this.controller,
    this.placeholder,
    this.onSubmit,
    this.style,
    this.placeholderStyle,
  });

  @override
  Size layout(BoxConstraints constraints) {
    // Always one row tall; take whatever width the parent offers.
    size = Size(constraints.maxWidth, constraints.constrainHeight(1));
    return size;
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    // Claim focus so stdin routes here.
    FocusManager.request(controller, onSubmit: onSubmit);

    // Paint the field's full-width background first so the coloured
    // area doesn't stop where the typed text stops.
    if (style != null) {
      canvas.fill(offset, size, ' ', style: style);
    }

    final text = controller.text;
    if (text.isEmpty && placeholder != null) {
      canvas.drawText(
        offset.dx,
        offset.dy,
        placeholder!,
        style: placeholderStyle ?? style,
      );
    } else {
      canvas.drawText(offset.dx, offset.dy, text, style: style);
    }

    // Park the real terminal cursor at the text cursor. For an empty
    // field we still place it at the start of the row so typing feels
    // natural.
    final cursorCol = offset.dx +
        (text.isEmpty ? 0 : controller.cursor.clamp(0, size.width - 1));
    FocusManager.cursor = Offset(cursorCol, offset.dy);
  }
}
