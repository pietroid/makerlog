import 'constraints.dart';
import 'text_editing_controller.dart';

/// Kinds of key events fly recognises. Anything not in this list
/// is surfaced as [KeyType.other] and generally ignored.
enum KeyType {
  character,
  enter,
  altEnter,
  backspace,
  tab,
  escape,
  ctrlC,
  ctrlD,
  arrowUp,
  arrowDown,
  arrowLeft,
  arrowRight,
  other,
}

/// A single decoded key event.
class KeyEvent {
  final KeyType type;

  /// The character, if [type] is [KeyType.character]. Otherwise null.
  final String? character;

  const KeyEvent(this.type, [this.character]);
}

/// Decodes a chunk of raw bytes from stdin into [KeyEvent]s. Handles:
///   * plain ASCII (space through ~)
///   * control keys (Ctrl-C, Enter, Backspace, Tab)
///   * CSI sequences for arrow keys (ESC [ A/B/C/D)
///   * Alt-modified keys (ESC + key, e.g. Alt+Enter)
///   * SGR mouse events (ESC [ < btn ; x ; y M/m)
///   * multi-byte UTF-8 so emoji and accented chars come through intact
///
/// It's forgiving: unknown sequences become [KeyType.other] so the
/// runtime keeps working on terminals we don't fully understand.
class KeyParser {
  static List<KeyEvent> parse(List<int> bytes) {
    final events = <KeyEvent>[];
    int i = 0;

    while (i < bytes.length) {
      final b = bytes[i];

      if (b == 3) {
        events.add(const KeyEvent(KeyType.ctrlC));
        i++;
      } else if (b == 4) {
        events.add(const KeyEvent(KeyType.ctrlD));
        i++;
      } else if (b == 13 || b == 10) {
        events.add(const KeyEvent(KeyType.enter));
        i++;
      } else if (b == 127 || b == 8) {
        events.add(const KeyEvent(KeyType.backspace));
        i++;
      } else if (b == 9) {
        events.add(const KeyEvent(KeyType.tab));
        i++;
      } else if (b == 27) {
        // ESC: CSI sequence, Alt+key, SGR mouse, or lone Escape.
        if (i + 2 < bytes.length && bytes[i + 1] == 91) {
          if (bytes[i + 2] == 60 && i + 5 < bytes.length) {
            // ESC [ < = SGR mouse event
            final mouse = _parseSgrMouse(bytes, i);
            if (mouse != null) {
              events.add(mouse);
              i += mouse._consumedBytes;
              continue;
            }
          }
          // CSI sequence (arrow keys, etc.)
          if (i + 2 < bytes.length) {
            switch (bytes[i + 2]) {
              case 65:
                events.add(const KeyEvent(KeyType.arrowUp));
              case 66:
                events.add(const KeyEvent(KeyType.arrowDown));
              case 67:
                events.add(const KeyEvent(KeyType.arrowRight));
              case 68:
                events.add(const KeyEvent(KeyType.arrowLeft));
              default:
                events.add(const KeyEvent(KeyType.other));
            }
            i += 3;
            continue;
          }
        } else if (i + 1 < bytes.length && (bytes[i + 1] == 13 || bytes[i + 1] == 10)) {
          // Alt+Enter (ESC followed by CR or LF)
          events.add(const KeyEvent(KeyType.altEnter));
          i += 2;
          continue;
        }
        events.add(const KeyEvent(KeyType.escape));
        i++;
      } else if (b >= 32 && b < 127) {
        events.add(KeyEvent(KeyType.character, String.fromCharCode(b)));
        i++;
      } else if (b >= 0xC0 && b < 0xF8) {
        // UTF-8 multi-byte leader. Determine how many continuation
        // bytes follow and gather them into one character.
        int len;
        if (b >= 0xF0) {
          len = 4;
        } else if (b >= 0xE0) {
          len = 3;
        } else {
          len = 2;
        }
        if (i + len <= bytes.length) {
          final str = String.fromCharCodes(bytes.sublist(i, i + len));
          events.add(KeyEvent(KeyType.character, str));
          i += len;
        } else {
          // Truncated sequence; skip.
          i++;
        }
      } else {
        // Some other control byte we don't care about.
        i++;
      }
    }

    return events;
  }

  /// SGR mouse protocol: ESC [ < btn ; x ; y (M | m)
  /// Returns the event plus how many bytes were consumed, or null
  /// if the sequence is malformed.
  static _MouseKeyEvent? _parseSgrMouse(List<int> bytes, int start) {
    // ESC [ <  already consumed at start..start+2
    var i = start + 3; // position after '<'
    final len = bytes.length;

    int readNum() {
      int n = 0;
      bool hasDigit = false;
      while (i < len && bytes[i] >= 48 && bytes[i] <= 57) {
        hasDigit = true;
        n = n * 10 + (bytes[i] - 48);
        i++;
      }
      return hasDigit ? n : -1;
    }

    final btn = readNum();
    if (btn < 0 || i >= len || bytes[i] != 59) return null;
    i++;
    final x = readNum();
    if (x < 0 || i >= len || bytes[i] != 59) return null;
    i++;
    final y = readNum();
    if (y < 0 || i >= len) return null;
    final release = bytes[i] == 109; // 'm'
    final press = bytes[i] == 77; // 'M'
    if (!press && !release) return null;
    i++;

    final kind = _mouseKind(btn, press);
    final m = MouseEvent(kind: kind, x: x - 1, y: y - 1);
    return _MouseKeyEvent(m, i - start);
  }

  static MouseEventKind _mouseKind(int btn, bool pressed) {
    // SGR button encoding:
    // 0 = left, 1 = middle, 2 = right
    // 64 = scroll up, 65 = scroll down
    if (btn == 64) return MouseEventKind.scrollUp;
    if (btn == 65) return MouseEventKind.scrollDown;
    return MouseEventKind.unknown;
  }
}

/// Kinds of mouse events the framework recognises.
enum MouseEventKind { scrollUp, scrollDown, unknown }

/// A decoded terminal mouse event.
class MouseEvent {
  final MouseEventKind kind;
  final int x;
  final int y;

  MouseEvent({required this.kind, required this.x, required this.y});
}

/// Internal wrapper so a mouse event can ride through [KeyParser.parse]
/// alongside regular [KeyEvent]s.
class _MouseKeyEvent extends KeyEvent {
  final MouseEvent mouse;
  final int _consumedBytes;

  _MouseKeyEvent(this.mouse, this._consumedBytes)
      : super(KeyType.other);
}

/// Records the currently focused TextField, along with the callback
/// that should fire on Enter. Widgets [re-request] focus every paint,
/// so this is simply overwritten rather than tracked as a tree.
class _FocusTarget {
  final TextEditingController controller;
  final void Function(String text)? onSubmit;
  final bool multiline;

  _FocusTarget(this.controller, this.onSubmit, {this.multiline = false});
}

/// Tiny global focus manager. The focused widget gets first dibs on
/// incoming keys; if it doesn't consume them they bubble to listeners.
class FocusManager {
  static _FocusTarget? _target;
  static final List<void Function(KeyEvent)> _keyListeners = [];
  static final List<void Function(MouseEvent)> _mouseListeners = [];

  /// Where the terminal cursor should be parked after the frame is
  /// painted. Set by TextField during paint.
  static Offset? cursor;

  /// Called by the runtime at the start of each frame. Focus is
  /// "elected" by the act of painting a TextField, so we clear first.
  static void reset() {
    _target = null;
    cursor = null;
    _keyListeners.clear();
    _mouseListeners.clear();
  }

  /// Mark [controller] as the focused input for this frame.
  static void request(
    TextEditingController controller, {
    void Function(String text)? onSubmit,
    bool multiline = false,
  }) {
    _target = _FocusTarget(controller, onSubmit, multiline: multiline);
  }

  /// Register a raw key callback for this frame.
  static void addKeyListener(void Function(KeyEvent) onKeyEvent) {
    _keyListeners.add(onKeyEvent);
  }

  /// Register a mouse-event callback for this frame.
  static void addMouseListener(void Function(MouseEvent) onMouseEvent) {
    _mouseListeners.add(onMouseEvent);
  }

  /// Route a decoded event. Keys are offered to the focused target
  /// first; if it doesn't consume them they are sent to listeners.
  /// Mouse events go straight to listeners.
  static void dispatch(KeyEvent event) {
    // Unwrap mouse events embedded in KeyEvent wrappers.
    if (event is _MouseKeyEvent) {
      for (final l in _mouseListeners) {
        l(event.mouse);
      }
      return;
    }

    final target = _target;
    if (target != null) {
      final consumed = _dispatchToTarget(event, target);
      if (consumed) return;
    }

    for (final l in _keyListeners) {
      l(event);
    }
  }

  static bool _dispatchToTarget(KeyEvent event, _FocusTarget target) {
    switch (event.type) {
      case KeyType.character:
        final c = event.character;
        if (c != null) {
          target.controller.insert(c);
          return true;
        }
        return false;
      case KeyType.backspace:
        target.controller.backspace();
        return true;
      case KeyType.enter:
        target.onSubmit?.call(target.controller.text);
        return true;
      case KeyType.altEnter:
        if (target.multiline) {
          target.controller.insert('\n');
          return true;
        }
        return false;
      case KeyType.arrowLeft:
        return target.controller.moveCursor(-1);
      case KeyType.arrowRight:
        return target.controller.moveCursor(1);
      case KeyType.arrowUp:
        if (target.multiline) {
          return target.controller.moveCursorUp();
        }
        return false;
      case KeyType.arrowDown:
        if (target.multiline) {
          return target.controller.moveCursorDown();
        }
        return false;
      default:
        return false;
    }
  }
}
