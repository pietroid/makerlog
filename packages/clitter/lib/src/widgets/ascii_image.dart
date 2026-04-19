import 'dart:io';

import '../build_context.dart';
import '../color.dart';
import '../text_style.dart';
import '../widget.dart';
import 'text.dart';

/// Renders a plain-text file (ASCII art) as a widget. The file is
/// read once on construction and rendered as-is — no wrapping, so
/// callers should ensure the terminal is wide enough.
class AsciiImage extends StatelessWidget {
  final String path;
  final Color? color;

  AsciiImage(this.path, {this.color});

  @override
  Widget build(BuildContext context) {
    final content = File(path).readAsStringSync();
    return Text(
      content,
      style: TextStyle(color: color),
    );
  }
}
