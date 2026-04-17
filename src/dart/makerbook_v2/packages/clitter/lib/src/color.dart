/// A colour that can be rendered as either an ANSI 16-colour code
/// (portable everywhere) or a 24-bit truecolor triple (modern
/// terminals). Named constants default to ANSI so they work even on
/// constrained environments; `Color.rgb(...)` opts into truecolor.
class Color {
  // Exactly one of these is set. `_ansi` takes precedence.
  final int? _ansi;
  final int _r;
  final int _g;
  final int _b;

  const Color._ansi(int code)
      : _ansi = code,
        _r = 0,
        _g = 0,
        _b = 0;

  /// Truecolor (24-bit). Each channel is clamped to 0..255 at paint time.
  const Color.rgb(int r, int g, int b)
      : _ansi = null,
        _r = r,
        _g = g,
        _b = b;

  // Standard 8. `Color.black` etc. match the terminal's palette so
  // users can theme their terminal and have apps follow along.
  static const Color black = Color._ansi(0);
  static const Color red = Color._ansi(1);
  static const Color green = Color._ansi(2);
  static const Color yellow = Color._ansi(3);
  static const Color blue = Color._ansi(4);
  static const Color magenta = Color._ansi(5);
  static const Color cyan = Color._ansi(6);
  static const Color white = Color._ansi(7);

  // Bright variants (the "high-intensity" half of the 16-colour set).
  static const Color brightBlack = Color._ansi(8);
  static const Color brightRed = Color._ansi(9);
  static const Color brightGreen = Color._ansi(10);
  static const Color brightYellow = Color._ansi(11);
  static const Color brightBlue = Color._ansi(12);
  static const Color brightMagenta = Color._ansi(13);
  static const Color brightCyan = Color._ansi(14);
  static const Color brightWhite = Color._ansi(15);

  /// SGR parameter(s) for using this colour in the foreground. The
  /// caller wraps the result in `\x1B[...m`.
  String get fgSgr {
    final a = _ansi;
    if (a != null) {
      return a < 8 ? '${30 + a}' : '${90 + a - 8}';
    }
    return '38;2;$_r;$_g;$_b';
  }

  /// SGR parameter(s) for using this colour in the background.
  String get bgSgr {
    final a = _ansi;
    if (a != null) {
      return a < 8 ? '${40 + a}' : '${100 + a - 8}';
    }
    return '48;2;$_r;$_g;$_b';
  }

  @override
  bool operator ==(Object other) =>
      other is Color &&
      other._ansi == _ansi &&
      other._r == _r &&
      other._g == _g &&
      other._b == _b;

  @override
  int get hashCode => Object.hash(_ansi, _r, _g, _b);
}
