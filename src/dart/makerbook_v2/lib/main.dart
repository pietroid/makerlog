import 'package:clitter/clitter.dart';
import 'package:hotreloader/hotreloader.dart';

import 'app/makerbook_app.dart';

/// Start the app. Run with:
///
///   dart run bin/makerbook.dart             (no hot reload)
///   dart run --enable-vm-service bin/makerbook.dart   (hot reload on)
///
/// While running:
///   * Type anything, press Enter to add a message
///   * Arrow keys move the cursor in the input
///   * Ctrl-C quits
///   * Resize the terminal — the layout re-flows automatically
Future<void> main(List<String> args) async {
  // Best-effort hot reload. HotReloader.create throws if the VM
  // service isn't enabled (plain `dart run`), so we swallow that and
  // continue — the user just won't get live code updates.
  try {
    await HotReloader.create(
      onAfterReload: (_) => clitterOnReload(),
    );
  } catch (_) {
    // VM service not available; that's fine.
  }

  await runApp(MakerbookApp());
}
