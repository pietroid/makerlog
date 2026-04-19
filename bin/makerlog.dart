// Executable entry. Keeps `bin/` minimal — all the work happens in
// `lib/main.dart` so that code is reachable from tests too.
import 'package:makerlog/main.dart' as app;

Future<void> main(List<String> args) => app.main(args);
