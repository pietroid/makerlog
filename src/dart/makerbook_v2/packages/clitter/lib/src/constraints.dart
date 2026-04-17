// Geometry primitives — named after their Flutter counterparts but
// measured in integer character cells (terminal grid) rather than
// fractional pixels.

/// Width/height in character cells.
class Size {
  final int width;
  final int height;

  const Size(this.width, this.height);
  const Size.zero()
      : width = 0,
        height = 0;

  @override
  String toString() => 'Size($width, $height)';
}

/// A position relative to some origin.
/// `dx` is column, `dy` is row (both 0-indexed).
class Offset {
  final int dx;
  final int dy;

  const Offset(this.dx, this.dy);
  const Offset.zero()
      : dx = 0,
        dy = 0;

  Offset operator +(Offset other) => Offset(dx + other.dx, dy + other.dy);

  @override
  String toString() => 'Offset($dx, $dy)';
}

/// Layout constraints passed down from a parent widget.
///
/// A widget must return a size that satisfies
///   minWidth <= size.width <= maxWidth
///   minHeight <= size.height <= maxHeight
class BoxConstraints {
  final int minWidth;
  final int maxWidth;
  final int minHeight;
  final int maxHeight;

  const BoxConstraints({
    this.minWidth = 0,
    required this.maxWidth,
    this.minHeight = 0,
    required this.maxHeight,
  });

  /// Constraints that force exactly [size].
  BoxConstraints.tight(Size size)
      : minWidth = size.width,
        maxWidth = size.width,
        minHeight = size.height,
        maxHeight = size.height;

  /// Same dimensions, no minimums.
  BoxConstraints loosen() => BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

  int constrainWidth(int w) {
    if (w < minWidth) return minWidth;
    if (w > maxWidth) return maxWidth;
    return w;
  }

  int constrainHeight(int h) {
    if (h < minHeight) return minHeight;
    if (h > maxHeight) return maxHeight;
    return h;
  }

  Size constrain(Size size) =>
      Size(constrainWidth(size.width), constrainHeight(size.height));
}
