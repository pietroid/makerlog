import 'dart:io';

import 'constraints.dart';

/// Thin wrapper over stdout/stdin that speaks ANSI. Owned by the
/// runtime; widgets never touch it directly.
///
/// Responsibilities:
///   * enter/exit raw mode so we see every keystroke
///   * switch to the alternate screen buffer so the user's shell
///     history is preserved on exit
///   * disable line-wrap so writing to the last column doesn't scroll
///   * position the cursor absolutely when painting a frame
class Terminal {
  bool _rawMode = false;
  bool _altScreen = false;

  /// Current terminal width in columns. Reads fresh each call so
  /// callers always see the current size after a SIGWINCH.
  int get width => stdout.hasTerminal ? stdout.terminalColumns : 80;

  /// Current terminal height in rows.
  int get height => stdout.hasTerminal ? stdout.terminalLines : 24;

  Size get size => Size(width, height);

  void enterRawMode() {
    if (!stdin.hasTerminal || _rawMode) return;
    // Wrap: when stdin is a fake TTY (piped input, some CI runners)
    // setting echoMode can throw even though hasTerminal was true.
    try {
      stdin.echoMode = false;
      stdin.lineMode = false;
      _rawMode = true;
    } on StdinException {
      // Best-effort — stay in cooked mode if the OS won't let us switch.
    }
  }

  void exitRawMode() {
    if (!_rawMode) return;
    try {
      stdin.lineMode = true;
      stdin.echoMode = true;
    } on StdinException {
      // Ignore: we're on our way out anyway.
    }
    _rawMode = false;
  }

  // Save the user's terminal state and give us a clean canvas.
  void enterAlternateScreen() {
    if (_altScreen) return;
    stdout.write('\x1B[?1049h'); // enter alt buffer
    stdout.write('\x1B[?7l'); // disable auto-wrap
    stdout.write('\x1B[2J\x1B[H'); // clear + home
    // DECSCUSR 6 = steady bar ("|"). We intentionally pick the
    // *steady* variant because the runtime blinks in software (see
    // runApp). Some terminals ignore DECSCUSR's blinking flag (e.g.
    // iTerm2 honours a user preference that overrides it), so doing
    // the blink ourselves is the only way to get consistent behaviour.
    stdout.write('\x1B[6 q');
    _altScreen = true;
  }

  void exitAlternateScreen() {
    if (!_altScreen) return;
    stdout.write('\x1B[0 q'); // restore the user's default cursor style
    stdout.write('\x1B[?7h'); // re-enable auto-wrap
    stdout.write('\x1B[?1049l'); // leave alt buffer
    _altScreen = false;
  }

  void hideCursor() => stdout.write('\x1B[?25l');
  void showCursor() => stdout.write('\x1B[?25h');

  /// Write a full frame. Each line in [lines] is positioned absolutely
  /// on its row, which sidesteps newline/auto-wrap pitfalls. If
  /// [cursor] is non-null the terminal cursor is parked there and made
  /// visible — that's how TextField shows a blinking caret.
  void renderFrame(List<String> lines, {Offset? cursor}) {
    final buf = StringBuffer();
    buf.write('\x1B[?25l'); // hide during paint to avoid flicker
    for (int i = 0; i < lines.length; i++) {
      buf.write('\x1B[${i + 1};1H'); // absolute position: row i+1, col 1
      buf.write(lines[i]);
    }
    if (cursor != null) {
      buf.write('\x1B[${cursor.dy + 1};${cursor.dx + 1}H');
      buf.write('\x1B[?25h');
    }
    stdout.write(buf.toString());
  }
}
