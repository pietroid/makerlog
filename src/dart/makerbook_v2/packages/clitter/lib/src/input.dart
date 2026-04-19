import 'constraints.dart';
import 'text_editing_controller.dart';

/// Kinds of key events clitter recognises. Anything not in this list
/// is surfaced as [KeyType.other] and generally ignored.
enum KeyType {
  character,
  enter,
  backspace,
  tab,
  escape,
  ctrlC,
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
        // ESC: may be a CSI sequence (ESC [ X) or a lone Escape press.
        if (i + 2 < bytes.length && bytes[i + 1] == 91) {
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
        } else {
          events.add(const KeyEvent(KeyType.escape));
          i++;
        }
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
}

/// Records the currently focused TextField, along with the callback
/// that should fire on Enter. Widgets [re-request] focus every paint,
/// so this is simply overwritten rather than tracked as a tree.
class _FocusTarget {
  final TextEditingController controller;
  final void Function(String text)? onSubmit;

  _FocusTarget(this.controller, this.onSubmit);
}

/// Tiny global focus manager. Intentionally simple: there is at most
/// one focused controller at a time, and it's the last one to call
/// [request] during a frame (typically: the only TextField on screen).
///
/// The alternative — a proper focus-traversal tree — is overkill for
/// the sample app and easy to add later.
class FocusManager {
  static _FocusTarget? _target;
  static final List<void Function(KeyEvent)> _listeners = [];

  /// Where the terminal cursor should be parked after the frame is
  /// painted. Set by TextField during paint.
  static Offset? cursor;

  /// Called by the runtime at the start of each frame. Focus is
  /// "elected" by the act of painting a TextField, so we clear first.
  static void reset() {
    _target = null;
    cursor = null;
    _listeners.clear();
  }

  /// Mark [controller] as the focused input for this frame.
  static void request(
    TextEditingController controller, {
    void Function(String text)? onSubmit,
  }) {
    _target = _FocusTarget(controller, onSubmit);
  }

  /// Register a raw key callback for this frame. Re-requested every
  /// paint by [KeyboardListener], mirroring how [request] works for
  /// text inputs. Listeners see every decoded key (minus Ctrl-C, which
  /// the runtime swallows for clean exit).
  static void addKeyListener(void Function(KeyEvent) onKeyEvent) {
    _listeners.add(onKeyEvent);
  }

  /// Route a key event to the focused controller. Called by the
  /// runtime once per decoded key.
  static void dispatch(KeyEvent event) {
    // Fan out to KeyboardListener widgets first so app-level handlers
    // (navigation, shortcuts) always see the event, even when a
    // TextField is focused.
    for (final l in _listeners) {
      l(event);
    }

    final target = _target;
    if (target == null) return;

    switch (event.type) {
      case KeyType.character:
        final c = event.character;
        if (c != null) target.controller.insert(c);
      case KeyType.backspace:
        target.controller.backspace();
      case KeyType.enter:
        target.onSubmit?.call(target.controller.text);
      case KeyType.arrowLeft:
        target.controller.moveCursor(-1);
      case KeyType.arrowRight:
        target.controller.moveCursor(1);
      default:
        // Unhandled keys are dropped on the floor.
        break;
    }
  }
}
