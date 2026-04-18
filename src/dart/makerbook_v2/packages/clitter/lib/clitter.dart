/// Clitter — Flutter-like framework for building CLI apps.
///
/// Import this single file to get the full public API:
///
///   import 'package:clitter/clitter.dart';
///
/// The design mirrors Flutter at the surface (Widget, StatelessWidget,
/// Column, Row, Text, TextField, BlocBuilder, ...) but underneath the
/// render target is a terminal and layout is measured in character
/// cells instead of pixels.
library clitter;

// Core runtime
export 'src/app.dart';
export 'src/widget.dart';
export 'src/build_context.dart';
export 'src/constraints.dart';
export 'src/canvas.dart';
export 'src/color.dart';
export 'src/text_style.dart';
export 'src/input.dart';
export 'src/text_editing_controller.dart';
export 'src/hot_reload.dart';

// Built-in widgets
export 'src/widgets/text.dart';
export 'src/widgets/text_field.dart';
export 'src/widgets/column.dart';
export 'src/widgets/row.dart';
export 'src/widgets/expanded.dart';
export 'src/widgets/sized_box.dart';
export 'src/widgets/padding.dart';
export 'src/widgets/center.dart';
export 'src/widgets/container.dart';

// BLoC integration — re-export the real `bloc` package so apps can
// `import 'package:clitter/clitter.dart';` and get Cubit/Bloc/etc.
// alongside clitter's own BlocBuilder.
export 'package:bloc/bloc.dart';
export 'src/bloc/bloc_builder.dart';
