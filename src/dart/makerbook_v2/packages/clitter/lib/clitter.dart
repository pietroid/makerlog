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
export 'src/framework.dart';
export 'src/build_context.dart';
export 'src/provider.dart';
export 'src/constraints.dart';
export 'src/canvas.dart';
export 'src/color.dart';
export 'src/text_style.dart';
export 'src/input.dart';
export 'src/text_editing_controller.dart';

// Built-in widgets
export 'src/widgets/text.dart';
export 'src/widgets/text_field.dart';
export 'src/widgets/flex.dart';
export 'src/widgets/column.dart';
export 'src/widgets/row.dart';
export 'src/widgets/expanded.dart';
export 'src/widgets/sized_box.dart';
export 'src/widgets/padding.dart';
export 'src/widgets/center.dart';
export 'src/widgets/container.dart';
export 'src/widgets/divider.dart';
export 'src/widgets/ascii_image.dart';
export 'src/widgets/keyboard_listener.dart';

// Bloc integration lives in the sibling `clitter_bloc` package so the
// core framework stays agnostic of any particular state-management
// library. Apps that want BlocProvider / BlocBuilder:
//   import 'package:clitter_bloc/clitter_bloc.dart';
