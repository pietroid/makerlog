import 'color.dart';
import 'constraints.dart';
import 'text_style.dart';

/// Internal per-cell state. Style lives alongside the character so
/// that drawing "text only" can preserve an existing background and
/// vice-versa — which is what makes Container + Text composition work
/// without every widget knowing about every other.
class _Cell {
  // All cells start in the terminal's default state and are mutated
  // in place by drawText/fill — keeps the constructor noise-free.
  String char = ' ';
  Color? fg;
  Color? bg;
  bool bold = false;
  bool italic = false;

  _Cell();

  /// Two cells render with the same SGR prefix iff every attribute
  /// matches. Used to coalesce runs during [Canvas.toLines].
  bool sameStyleAs(_Cell other) =>
      fg == other.fg &&
      bg == other.bg &&
      bold == other.bold &&
      italic == other.italic;
}

/// A grid of character cells with per-cell colour/weight/italic. The
/// runtime creates one per frame sized to the terminal; widgets paint
/// into it; the terminal flushes the result.
///
/// Composition model: applying a TextStyle only *overrides* the
/// attributes it specifies. Colours are nullable, so `null` means
/// "leave whatever's there". Weight/italic are enums, so they always
/// get written — that's deliberate; explicit TextStyle(bold:...) will
/// turn boldness on or off, but passing `style: null` entirely won't
/// touch it.
class Canvas {
  final int width;
  final int height;
  final List<List<_Cell>> _cells;

  Canvas(this.width, this.height)
      : _cells = List.generate(
          height,
          (_) => List.generate(width, (_) => _Cell()),
        );

  /// Draw a run of text starting at ([x], [y]). Cells out of bounds
  /// are silently clipped.
  void drawText(int x, int y, String text, {TextStyle? style}) {
    if (y < 0 || y >= height) return;
    int col = x;
    for (final rune in text.runes) {
      if (col >= width) break;
      if (col >= 0) {
        final cell = _cells[y][col];
        cell.char = String.fromCharCode(rune);
        _applyStyle(cell, style);
      }
      col++;
    }
  }

  /// Fill a rectangle with [char]. Used by Container for a solid
  /// background and by TextField to paint its field area.
  void fill(Offset offset, Size size, String char, {TextStyle? style}) {
    final ch = char.isEmpty ? ' ' : char[0];
    for (int dy = 0; dy < size.height; dy++) {
      final y = offset.dy + dy;
      if (y < 0 || y >= height) continue;
      for (int dx = 0; dx < size.width; dx++) {
        final x = offset.dx + dx;
        if (x < 0 || x >= width) continue;
        final cell = _cells[y][x];
        cell.char = ch;
        _applyStyle(cell, style);
      }
    }
  }

  // Layer [style] onto [cell], preserving fields that style leaves
  // null. This is the merge rule that makes nested widgets compose.
  static void _applyStyle(_Cell cell, TextStyle? style) {
    if (style == null) return;
    if (style.color != null) cell.fg = style.color;
    if (style.backgroundColor != null) cell.bg = style.backgroundColor;
    cell.bold = style.fontWeight == FontWeight.bold;
    cell.italic = style.fontStyle == FontStyle.italic;
  }

  /// Render each row to a string with embedded ANSI SGR sequences.
  /// Consecutive cells that share attributes reuse one SGR prefix, so
  /// a solid-colour row produces just one escape per line instead of
  /// one per cell.
  List<String> toLines() {
    return List.generate(height, (y) {
      final sb = StringBuffer();
      _Cell? last;
      for (int x = 0; x < width; x++) {
        final cell = _cells[y][x];
        if (last == null || !cell.sameStyleAs(last)) {
          // Reset first so turning an attribute *off* works correctly
          // (SGR doesn't have cancel-bold without a reset).
          sb.write('\x1B[0m');
          final parts = <String>[];
          if (cell.fg != null) parts.add(cell.fg!.fgSgr);
          if (cell.bg != null) parts.add(cell.bg!.bgSgr);
          if (cell.bold) parts.add('1');
          if (cell.italic) parts.add('3');
          if (parts.isNotEmpty) sb.write('\x1B[${parts.join(';')}m');
          last = cell;
        }
        sb.write(cell.char);
      }
      // Always reset at line end so the absolute-positioning jump to
      // the next line doesn't inherit stale colours.
      sb.write('\x1B[0m');
      return sb.toString();
    });
  }
}
