import 'dart:async';
import 'dart:io';

import 'canvas.dart';
import 'constraints.dart';
import 'input.dart';
import 'terminal.dart';
import 'widget.dart';

/// Global handle to the currently running app. Exposes
/// [scheduleRebuild] so BLoCs and controllers can trigger a repaint
/// without needing a BuildContext or subscription.
class App {
  static VoidCallback? _scheduleRebuild;

  /// Ask the runtime to paint a new frame on the next microtask. Safe
  /// to call many times per tick — it coalesces to a single paint.
  static void scheduleRebuild() => _scheduleRebuild?.call();
}

typedef VoidCallback = void Function();

/// Entry point — like Flutter's `runApp`, but blocks until the
/// process is asked to quit (Ctrl-C, SIGTERM, SIGINT).
///
/// Takes a single root widget. The widget tree is rebuilt whenever:
///   * a key is pressed
///   * a BLoC emits a new state
///   * a TextEditingController is mutated
///   * the terminal is resized (SIGWINCH)
///   * a hot reload fires (see hot_reload.dart)
Future<void> runApp(Widget root) async {
  final terminal = Terminal();

  terminal.enterRawMode();
  terminal.enterAlternateScreen();
  terminal.hideCursor();

  // Software cursor blink. Flipped by a 500ms periodic timer; the
  // next `render()` looks at this flag and either forwards
  // FocusManager.cursor to the terminal or passes null to hide it.
  // Why do this ourselves instead of relying on DECSCUSR "blinking
  // bar"? Because some terminals (iTerm2 being the biggest offender)
  // gate the blink behind a user preference that an ANSI sequence
  // can't override.
  bool cursorVisible = true;
  Timer? blinkTimer;

  var cleanedUp = false;
  void cleanup() {
    if (cleanedUp) return;
    cleanedUp = true;
    blinkTimer?.cancel();
    terminal.showCursor();
    terminal.exitAlternateScreen();
    terminal.exitRawMode();
  }

  // Make sure we restore the terminal on any exit path. Without
  // this, a crash would leave the shell in raw mode.
  ProcessSignal.sigint.watch().listen((_) {
    cleanup();
    exit(0);
  });
  // SIGTERM is only available on POSIX; on Windows it's a no-op.
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) {
      cleanup();
      exit(0);
    });
    // SIGWINCH fires whenever the terminal is resized — repaint.
    ProcessSignal.sigwinch.watch().listen((_) => App.scheduleRebuild());
  }

  // Render-loop plumbing. `scheduled` coalesces multiple mutations
  // in the same microtask down to one paint.
  bool scheduled = false;

  void render() {
    scheduled = false;
    final size = terminal.size;
    if (size.width <= 0 || size.height <= 0) return;

    FocusManager.reset();
    final canvas = Canvas(size.width, size.height);
    root.layout(BoxConstraints.tight(size));
    root.paint(canvas, const Offset.zero());
    // During the "off" phase of the blink we pass null so the cursor
    // is hidden by the terminal. The next tick paints it back.
    terminal.renderFrame(
      canvas.toLines(),
      cursor: cursorVisible ? FocusManager.cursor : null,
    );
  }

  App._scheduleRebuild = () {
    if (scheduled) return;
    scheduled = true;
    scheduleMicrotask(render);
  };

  // Kick the blink timer. resetBlink() pins the cursor to "on" and
  // restarts the 500ms flip — called on startup and on every
  // keystroke so active typing doesn't strobe.
  void resetBlink() {
    blinkTimer?.cancel();
    cursorVisible = true;
    blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      cursorVisible = !cursorVisible;
      App.scheduleRebuild();
    });
  }

  // Wire stdin -> KeyParser -> FocusManager. Ctrl-C is handled here
  // rather than via SIGINT so that it works even on terminals where
  // raw mode swallows the signal.
  stdin.listen(
    (bytes) {
      resetBlink();
      for (final event in KeyParser.parse(bytes)) {
        if (event.type == KeyType.ctrlC) {
          cleanup();
          exit(0);
        }
        FocusManager.dispatch(event);
      }
      App.scheduleRebuild();
    },
    onError: (_) {},
  );

  // Start the blink and paint once so the user sees something before
  // pressing a key.
  resetBlink();
  render();

  // Keep the isolate alive. runApp returns only when the process
  // exits, matching Flutter's behaviour.
  final done = Completer<void>();
  return done.future;
}
