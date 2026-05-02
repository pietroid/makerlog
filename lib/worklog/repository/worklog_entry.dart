/// A single entry in the worklog.
///
/// The worklog file is the single source of truth; each non-empty line
/// becomes one [WorklogEntry].
class WorklogEntry {
  final String text;

  WorklogEntry({required this.text});

  /// Serialises to a plain line of text.
  String toMarkdown() => text;

  /// Parses a non-empty line from the worklog file.
  static WorklogEntry? fromMarkdown(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;
    return WorklogEntry(text: trimmed);
  }
}
