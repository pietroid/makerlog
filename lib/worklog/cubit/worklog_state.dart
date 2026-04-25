import 'package:makerlog/worklog/repository/worklog_entry.dart';

/// Immutable snapshot of the worklog screen.
///
/// * [entries] — the full history, oldest first.
/// * [awaitingInput] — whether the text field is active.
class WorklogState {
  final List<WorklogEntry> entries;
  final bool awaitingInput;

  const WorklogState({
    this.entries = const [],
    this.awaitingInput = true,
  });

  WorklogState copyWith({
    List<WorklogEntry>? entries,
    bool? awaitingInput,
  }) {
    return WorklogState(
      entries: entries ?? this.entries,
      awaitingInput: awaitingInput ?? this.awaitingInput,
    );
  }
}
