import 'package:clitter/clitter.dart';

/// Top banner — a coloured bar with the app name in bold. Uses
/// Container for the background so the colour extends edge-to-edge,
/// and a Text inside for the title itself.
class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Color.rgb(0, 0, 0),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 2,
          top: 1,
          bottom: 1,
          right: 2,
        ),
        child: Text(
          'makerbook',
          style: TextStyle(
            color: Color.rgb(200, 255, 160),
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
