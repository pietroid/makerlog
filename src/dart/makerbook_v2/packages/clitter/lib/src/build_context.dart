/// A minimal stand-in for Flutter's BuildContext. It's threaded
/// through `build()` calls so future extensions (inherited widgets,
/// BlocProvider lookup, theming) have a place to live.
///
/// For now it's deliberately empty — the makerbook sample wires BLoCs
/// through constructors instead of context lookup to stay simple.
class BuildContext {
  const BuildContext();
}
