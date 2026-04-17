import 'app.dart';

/// Hook to wire into a hot-reload mechanism (typically the
/// `hotreloader` package). After the VM applies new code, call this
/// to force a repaint with the freshly-loaded widgets.
///
/// Example in your app's `main`:
///
/// ```dart
/// import 'package:hotreloader/hotreloader.dart';
///
/// await HotReloader.create(onAfterReload: (_) => clitterOnReload());
/// await runApp(MyApp());
/// ```
///
/// Kept in clitter (not the app) so the framework owns the contract:
/// "after a reload, schedule a rebuild."
void clitterOnReload() => App.scheduleRebuild();
