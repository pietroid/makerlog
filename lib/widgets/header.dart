import 'package:fly/fly.dart';

/// Top banner — a coloured bar with the app name in bold. Uses
/// Container for the background so the colour extends edge-to-edge,
/// and a Text inside for the title itself.
class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      border: Border(style: LineStyle.thin, color: Color.rgb(0, 150, 100)),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 1,
          top: 0,
          bottom: 0,
          right: 1,
        ),
        child: Text(
          'makerlog',
          style: TextStyle(
            color: Color.rgb(0, 200, 150),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
