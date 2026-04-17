import 'color.dart';

/// Weight for rendered text. Terminal fonts don't have a full weight
/// axis — "bold" maps to the ANSI bold attribute, everything else is
/// "regular".
enum FontWeight { regular, bold }

/// Either upright or italic. Italic support depends on the terminal
/// font; terminals that don't support italics usually render it as
/// underline or just ignore it.
enum FontStyle { normal, italic }

/// Styling for a run of text. Mirrors a small, useful subset of
/// Flutter's TextStyle — only the attributes that map cleanly to
/// ANSI SGR: foreground colour, background colour, bold, italic.
///
/// Any field left null (or at its default) is treated as "don't
/// override" when painted: the underlying canvas cell's existing
/// attribute is preserved. That's how a `Text` drawn on top of a
/// coloured `Container` keeps the container's background without
/// having to repeat it.
class TextStyle {
  final Color? color;
  final Color? backgroundColor;
  final FontWeight fontWeight;
  final FontStyle fontStyle;

  const TextStyle({
    this.color,
    this.backgroundColor,
    this.fontWeight = FontWeight.regular,
    this.fontStyle = FontStyle.normal,
  });

  /// True if nothing in this style would produce an ANSI sequence —
  /// i.e., painting with it is identical to painting with null.
  bool get isEmpty =>
      color == null &&
      backgroundColor == null &&
      fontWeight == FontWeight.regular &&
      fontStyle == FontStyle.normal;

  @override
  bool operator ==(Object other) =>
      other is TextStyle &&
      other.color == color &&
      other.backgroundColor == backgroundColor &&
      other.fontWeight == fontWeight &&
      other.fontStyle == fontStyle;

  @override
  int get hashCode =>
      Object.hash(color, backgroundColor, fontWeight, fontStyle);
}
