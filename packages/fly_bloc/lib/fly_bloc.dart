/// Bloc bindings for fly. Mirrors the surface of `flutter_bloc`:
///
///   import 'package:fly_bloc/fly_bloc.dart';
///
/// Gives you [BlocProvider] and [BlocBuilder] wired into fly's
/// [BuildContext] provider lookup.
library fly_bloc;

export 'package:bloc/bloc.dart';
export 'src/bloc_provider.dart';
export 'src/bloc_builder.dart';
