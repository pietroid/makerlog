import '../canvas.dart';
import '../constraints.dart';
import '../framework.dart';
import '../widget.dart';

/// Centres a [child] inside the space its parent grants. Takes the
/// full available area so "centre" means centred in the parent, not
/// in a shrink-wrapped box.
class Center extends Widget {
  final Widget child;

  Center({required this.child});

  @override
  Size layout(BoxConstraints constraints) {
    Framework.layoutChild(child, constraints.loosen());
    size = Size(constraints.maxWidth, constraints.maxHeight);
    return size;
  }

  @override
  void paint(Canvas canvas, Offset offset) {
    final dx = offset.dx + (size.width - child.size.width) ~/ 2;
    final dy = offset.dy + (size.height - child.size.height) ~/ 2;
    child.paint(canvas, Offset(dx, dy));
  }
}
