import 'package:clitter/clitter.dart';

/// Top banner — a coloured bar with the app name in bold. Uses
/// Container for the background so the colour extends edge-to-edge,
/// and a Text inside for the title itself.
class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.blue,
      height: 1,
      padding: const EdgeInsets.symmetric(horizontal: 1),
      // The text inherits the container's blue background thanks to
      // the canvas merge rule — we only specify foreground here.
      child: Text(
        'makerbook',
        style: const TextStyle(
          color: Color.brightWhite,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
