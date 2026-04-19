import 'package:fly/fly.dart';

import 'app/makerbook_app.dart';

/// Start the app. Run with:
///
///   dart run bin/makerbook.dart                        (no hot reload)
///   dart run --enable-vm-service bin/makerbook.dart    (hot reload on)
///
/// While running:
///   * Type anything, press Enter to add a message
///   * Arrow keys move the cursor in the input
///   * Ctrl-C quits
///   * Resize the terminal — the layout re-flows automatically
Future<void> main(List<String> args) => runApp(MakerbookApp());
