import 'app.dart';

/// Mutable text + cursor pair that TextField reads from. Lives
/// outside the widget tree so that rebuilding the tree each frame
/// doesn't lose the user's in-progress input.
///
/// Any mutation schedules a rebuild so the UI stays in sync without
/// the caller having to remember.
class TextEditingController {
  String _text;
  int _cursor;

  TextEditingController({String text = ''})
      : _text = text,
        _cursor = text.length;

  String get text => _text;

  /// Cursor position, in characters, in the range [0, text.length].
  int get cursor => _cursor;

  /// Insert [s] at the current cursor, then advance the cursor past it.
  void insert(String s) {
    _text = _text.substring(0, _cursor) + s + _text.substring(_cursor);
    _cursor += s.length;
    App.scheduleRebuild();
  }

  /// Delete the character immediately before the cursor.
  void backspace() {
    if (_cursor == 0) return;
    _text = _text.substring(0, _cursor - 1) + _text.substring(_cursor);
    _cursor -= 1;
    App.scheduleRebuild();
  }

  /// Move the cursor horizontally by [delta], clamped to the text
  /// bounds. Returns `true` iff the cursor actually changed.
  bool moveCursor(int delta) {
    final next = (_cursor + delta).clamp(0, _text.length);
    if (next == _cursor) return false;
    _cursor = next;
    App.scheduleRebuild();
    return true;
  }

  /// Move the cursor to the same column on the previous logical line
  /// (delimited by `\n`). Returns `true` iff the cursor moved.
  bool moveCursorUp() {
    if (_cursor == 0) return false;
    final textBefore = _text.substring(0, _cursor);
    final currentLineStart = textBefore.lastIndexOf('\n') + 1;
    if (currentLineStart == 0) return false; // already on first line

    final col = _cursor - currentLineStart;
    final prevText = _text.substring(0, currentLineStart - 1);
    final prevLineStart = prevText.lastIndexOf('\n') + 1;
    final prevLineLength = (currentLineStart - 1) - prevLineStart;
    _cursor = prevLineStart + col.clamp(0, prevLineLength);
    App.scheduleRebuild();
    return true;
  }

  /// Move the cursor to the same column on the next logical line
  /// (delimited by `\n`). Returns `true` iff the cursor moved.
  bool moveCursorDown() {
    final nextNewline = _text.indexOf('\n', _cursor);
    if (nextNewline == -1) return false;

    final currentLineStart = _text.lastIndexOf('\n', _cursor - 1) + 1;
    final col = _cursor - currentLineStart;
    final nextLineStart = nextNewline + 1;
    final nextNextNewline = _text.indexOf('\n', nextLineStart);
    final nextLineEnd = nextNextNewline == -1 ? _text.length : nextNextNewline;
    _cursor = nextLineStart + col.clamp(0, nextLineEnd - nextLineStart);
    App.scheduleRebuild();
    return true;
  }

  /// Reset to empty text.
  void clear() {
    _text = '';
    _cursor = 0;
    App.scheduleRebuild();
  }
}
