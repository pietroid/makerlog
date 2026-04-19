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

  /// Move the cursor by [delta], clamped to the text bounds.
  void moveCursor(int delta) {
    _cursor = (_cursor + delta).clamp(0, _text.length);
    App.scheduleRebuild();
  }

  /// Reset to empty text.
  void clear() {
    _text = '';
    _cursor = 0;
    App.scheduleRebuild();
  }
}
