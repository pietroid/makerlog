import '../canvas.dart';
import '../constraints.dart';
import '../widget.dart';

/// Marker widget: inside a Column or Row, an [Expanded] child is
/// sized to fill the leftover main-axis space. When there are several,
/// they share the remainder in proportion to their [flex] weights.
///
/// Outside a Column/Row, Expanded just sizes to its constraints.
class Expanded extends Widget {
  final int flex;
  final Widget child;

  Expanded({this.flex = 1, required this.child});

  @override
  Size layout(BoxConstraints constraints) {
    final childSize = child.layout(constraints);
    size = constraints.constrain(childSize);
    return size;
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    child.paint(canvas, offset);
  }
}
