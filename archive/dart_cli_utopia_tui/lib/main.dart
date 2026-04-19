import 'dart:async';

import 'package:hotreloader/hotreloader.dart';
import 'package:utopia_tui/utopia_tui.dart';

class MyApp extends TuiApp {
  @override
  void build(TuiContext context) {
    TuiColumn(
      children: [
        TuiPanelBox(title: 'Makerbook', child: TuiText('22:23')),
        TuiPanelBox(
          title: 'Makerbook',
          child: TuiText('Welcome to Utopia TUI!'),
        ),
        TuiTextInput(text: 'Type something...'),
      ],
      heights: [-1, -1, -1],
    ).paint(
      context,
      row: 2,
      col: 2,
      width: context.width - 4,
      height: context.height - 4,
    );
  }
}

void main() async {
  final runner = TuiRunner(MyApp());
  await runner.run();
  // await HotReloader.create(
  //   onAfterReload: (ctx) {
  //     TuiRunner(MyApp()).run();
  //   },
  // );
}
